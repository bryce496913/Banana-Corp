#!/usr/bin/env python3
"""Structural checks only; --app-bundle also checks an actual Xcode product.

No third-party parser or Apple SDK required. This accepts the OpenStep plist
syntax used by this project and rejects duplicate keys rather than dropping them.
"""
import argparse
import json
from pathlib import Path
import plistlib
import re
import struct
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
PROJECT_DIR = ROOT / "Banana Corp"
APP_DIR = PROJECT_DIR / "Banana Corp"
PROJECT = PROJECT_DIR / "Banana Corp.xcodeproj"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def parse_project(text):
    pattern = re.compile(r'\s+|/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|[{}()=;,]|[^\s{}()=;,"/]+', re.S)
    tokens, position = [], 0
    for match in pattern.finditer(text):
        require(match.start() == position, "Unrecognized project syntax")
        position = match.end()
        token = match.group()
        if not token.isspace() and not token.startswith(("/*", "//")):
            tokens.append(token)
    require(position == len(text), "Incomplete project syntax")
    index = 0

    def consume(expected=None):
        nonlocal index
        require(index < len(tokens), "Unexpected end of project")
        value = tokens[index]
        index += 1
        require(expected is None or value == expected, f"Expected {expected}, found {value}")
        return value

    def value():
        token = consume()
        if token == "{":
            result = {}
            while tokens[index] != "}":
                key = consume()
                key = json.loads(key) if key.startswith('"') else key
                require(key not in result, f"Duplicate project key: {key}")
                consume("=")
                result[key] = value()
                consume(";")
            consume("}")
            return result
        if token == "(":
            result = []
            while tokens[index] != ")":
                result.append(value())
                if tokens[index] != ")":
                    consume(",")
            consume(")")
            return result
        return json.loads(token) if token.startswith('"') else token

    result = value()
    require(index == len(tokens), "Trailing project syntax")
    return result


def check_project():
    project = parse_project((PROJECT / "project.pbxproj").read_text())
    objects = project["objects"]
    root = objects[project["rootObject"]]
    paths = {}

    def walk(identifier, parent):
        obj = objects[identifier]
        tree = obj.get("sourceTree", "<group>")
        if tree == "BUILT_PRODUCTS_DIR":
            return
        require(tree in {"<group>", "SOURCE_ROOT"}, f"Unexpected source tree: {tree}")
        path = (PROJECT_DIR if tree == "SOURCE_ROOT" else parent) / obj.get("path", "")
        if obj["isa"] == "PBXGroup":
            for child in obj.get("children", []):
                walk(child, path)
        else:
            require(path.exists(), f"Missing project file: {path}")
            require(identifier not in paths, f"Duplicate group placement: {path}")
            paths[identifier] = path

    walk(root["mainGroup"], PROJECT_DIR)
    # Every object reference, including target dependencies, must resolve.
    def references(value):
        if isinstance(value, dict):
            for child in value.values():
                references(child)
        elif isinstance(value, list):
            for child in value:
                references(child)
        elif isinstance(value, str) and re.fullmatch(r"[A-F0-9]{24}", value):
            require(value in objects, f"Unresolved project object: {value}")
    references(project)
    targets = {objects[id]["name"]: (id, objects[id]) for id in root["targets"]}
    require(set(targets) == {"Banana Corp", "Banana CorpTests", "Banana CorpUITests"}, "Unexpected target inventory")

    def settings(identifier):
        configs = objects[objects[identifier]["buildConfigurationList"]]["buildConfigurations"]
        return {objects[id]["name"]: objects[id]["buildSettings"] for id in configs}

    project_settings = settings(project["rootObject"])
    for name, (identifier, target) in targets.items():
        configs = settings(identifier)
        require(set(configs) == {"Debug", "Release"}, f"Missing configurations: {name}")
        for config, values in configs.items():
            combined = project_settings[config] | values
            require(combined["IPHONEOS_DEPLOYMENT_TARGET"] == "18.0", f"Wrong deployment target: {name}")
            require(combined["SWIFT_VERSION"] == "5.0", f"Wrong Swift language mode: {name}")
            require(combined["TARGETED_DEVICE_FAMILY"] == "1", f"Wrong device family: {name}")
            require(combined["SDKROOT"] == "iphoneos", f"Wrong SDK: {name}")
            require(combined["SUPPORTED_PLATFORMS"] == "iphoneos iphonesimulator", f"Wrong platforms: {name}")
            require(combined["GENERATE_INFOPLIST_FILE"] == "YES", f"Missing generated Info.plist: {name}")
            require("DEBUG" in combined.get("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "") if config == "Debug" else "DEBUG" not in combined.get("SWIFT_ACTIVE_COMPILATION_CONDITIONS", ""), f"Incorrect DEBUG boundary: {name}")
            if name == "Banana Corp":
                require(combined["PRODUCT_MODULE_NAME"] == "Banana_Corp", "App test import/module mismatch")
                require(combined["INFOPLIST_KEY_UIStatusBarHidden"] == "YES", "Status bar hiding missing")
                require(combined.get("INFOPLIST_KEY_UIStatusBarStyle") != "", "Invalid empty status bar style")
                with (PROJECT_DIR / combined["INFOPLIST_FILE"]).open("rb") as file:
                    plistlib.load(file)
                if "CODE_SIGN_ENTITLEMENTS" in combined:
                    require((PROJECT_DIR / combined["CODE_SIGN_ENTITLEMENTS"]).is_file(), "Missing entitlements")
            elif name.endswith("UITests"):
                require(combined["TEST_TARGET_NAME"] == "Banana Corp", "UI test app not assigned")
            else:
                require("Banana Corp.app" in combined["TEST_HOST"] and combined["BUNDLE_LOADER"] == "$(TEST_HOST)", "Unit test host missing")
        phases = {objects[id]["isa"]: objects[id] for id in target["buildPhases"]}
        require(len(target["buildPhases"]) == 3 and set(phases) == {"PBXSourcesBuildPhase", "PBXFrameworksBuildPhase", "PBXResourcesBuildPhase"}, f"Unexpected or duplicate build phases: {name}")
        def files(phase):
            ids = phases[phase]["files"]
            result = [paths[objects[id]["fileRef"]] for id in ids]
            require(len(result) == len(set(result)), f"Duplicate build inputs: {name}/{phase}")
            return set(result)
        sources = files("PBXSourcesBuildPhase")
        expected = set((PROJECT_DIR / name).glob("*.swift"))
        require(sources == expected, f"Incorrect source membership: {name}: {sources ^ expected}")
        if name == "Banana Corp":
            resources = files("PBXResourcesBuildPhase")
            expected = {APP_DIR / "StoryContent.json", APP_DIR / "RestrictedAccess.json", APP_DIR / "Assets.xcassets", APP_DIR / "Preview Content/Preview Assets.xcassets"}
            require(resources == expected, f"Incorrect production resource membership: {resources ^ expected}")
        else:
            require(not files("PBXResourcesBuildPhase"), "Fixtures must not be copied into app/test bundle")
            require(any(objects[id]["target"] == targets["Banana Corp"][0] for id in target["dependencies"]), "Test target lacks app dependency")
    scheme = ET.parse(PROJECT / "xcshareddata/xcschemes/Banana Corp.xcscheme")
    for reference in scheme.findall(".//BuildableReference"):
        target = objects[reference.attrib["BlueprintIdentifier"]]
        require(reference.attrib["ReferencedContainer"] == "container:Banana Corp.xcodeproj", "Scheme project container mismatch")
        require(target["name"] == reference.attrib["BlueprintName"], "Scheme target mismatch")
        require(objects[target["productReference"]]["path"] == reference.attrib["BuildableName"], "Scheme product mismatch")
    testables = scheme.findall(".//TestableReference")
    require(len(testables) == 2 and all(t.attrib["skipped"] == "NO" for t in testables), "Scheme tests unavailable")
    require({t.find("BuildableReference").attrib["BlueprintIdentifier"] for t in testables} == {targets["Banana CorpTests"][0], targets["Banana CorpUITests"][0]}, "Wrong or duplicate scheme test targets")
    print(f"PASS: parsed project, 3 targets, {len(list(APP_DIR.glob('*.swift')))} app sources, test membership, shared scheme and Debug/Release configuration")


def check_resources():
    content = json.loads((APP_DIR / "StoryContent.json").read_text())
    access = json.loads((APP_DIR / "RestrictedAccess.json").read_text())
    require(access["kind"] == "production", "Fixture catalogue in production")
    puzzles = {p["id"]: p for p in access["puzzles"]}
    require(puzzles["puzzle.banana_wall.pending_design"]["rule"]["kind"] == "awaitingApproval", "Retired pending gate must remain inert")
    require(puzzles["puzzle.banana_wall.review_cross_reference"]["rule"]["kind"] == "exactFields", "Approved puzzle missing")
    for asset in content.get("assets", []):
        require((APP_DIR / asset["fileName"]).is_file(), f"Missing media: {asset['fileName']}")
    for metadata in (APP_DIR / "Assets.xcassets").rglob("Contents.json"):
        data = json.loads(metadata.read_text())
        require(data.get("info", {}).get("version") == 1, f"Missing asset catalogue metadata: {metadata}")
        for item in data.get("images", []):
            if "filename" not in item:
                continue
            path = metadata.parent / item["filename"]
            require(path.is_file(), f"Missing image: {path}")
            if metadata.parent.suffix == ".appiconset":
                width, height = struct.unpack(">II", path.read_bytes()[16:24])
                size = [float(v) * float(item["scale"].rstrip("x")) for v in item["size"].split("x")]
                require([width, height] == size, f"Wrong icon dimensions: {path}")
    entry_points = sum(len(re.findall(r"@main\b", p.read_text())) for p in APP_DIR.glob("*.swift"))
    require(entry_points == 1, "App must have one entry point")
    route_source = (APP_DIR / "PhoneAppRoute.swift").read_text()
    routes = re.findall(r"^    case (\w+)\s*$", route_source, re.M)
    destinations = (APP_DIR / "ContentView.swift").read_text()
    metadata = (APP_DIR / "BananaAppIcon.swift").read_text()
    for route in routes:
        require(f"case .{route}:" in destinations and f"case .{route}:" in metadata, f"Unregistered route: {route}")
    print(f"PASS: local resource references, icon dimensions, one app entry and {len(routes)} route destinations; Swift catalogue validation runs separately")


def check_bundle(bundle):
    require(bundle.is_dir() and bundle.suffix == ".app", "Provide a built .app directory")
    with (bundle / "Info.plist").open("rb") as file:
        info = plistlib.load(file)
    require(info["MinimumOSVersion"] == "18.0", "Built minimum OS mismatch")
    require(info["UIStatusBarHidden"] is True, "Built status bar configuration mismatch")
    require(info["UIDeviceFamily"] == [1], "Built device family mismatch")
    require((bundle / info["CFBundleExecutable"]).is_file(), "Built executable missing")
    require((bundle / "Assets.car").is_file(), "Compiled asset catalogue missing")
    for name in ["StoryContent.json", "RestrictedAccess.json"]:
        require((bundle / name).read_bytes() == (APP_DIR / name).read_bytes(), f"Built resource differs/missing: {name}")
    for asset in json.loads((APP_DIR / "StoryContent.json").read_text()).get("assets", []):
        require((bundle / asset["fileName"]).read_bytes() == (APP_DIR / asset["fileName"]).read_bytes(), "Built media missing/changed")
    require(not any("fixture" in p.name.lower() and p.suffix == ".json" for p in bundle.rglob("*")), "Fixture JSON leaked into app bundle")
    print(f"PASS: actual built bundle Info.plist, executable, compiled assets and exact production resource bytes: {bundle}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app-bundle", type=Path)
    args = parser.parse_args()
    try:
        check_project()
        check_resources()
        if args.app_bundle:
            check_bundle(args.app_bundle)
        else:
            print("STATIC ONLY: no built .app supplied; bundling/runtime behavior not verified")
    except (ValueError, KeyError, IndexError, OSError, json.JSONDecodeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
