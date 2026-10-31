#!/usr/bin/env python3
import argparse
import ast
import importlib
import importlib.metadata
import os
import re
import sys


# Modules that are always available and should not be checked
BUILTIN_MODULES = set(sys.stdlib_module_names) | {
    'odoo',
    'openerp',
}

# Pip package names whose import name is different
IMPORT_NAMES = {
    'beautifulsoup4': 'bs4',
    'pillow': 'PIL',
    'psycopg2-binary': 'psycopg2',
    'python-dateutil': 'dateutil',
    'python-jose': 'jose',
    'python-slugify': 'slugify',
    'python_slugify': 'slugify',
    'pyyaml': 'yaml',
}

# Files Odoo imports before it reads the manifest
IMPORTED_FILES = [
    '__init__.py',
    'hooks.py',
    os.path.join('hooks', '__init__.py'),
]


def distribution_name(requirement):
    # "fsspec[s3]>=2024" -> "fsspec"
    return re.split(r'[\[<>=!~; ]', requirement.strip(), 1)[0]


def is_installed(requirement):
    name = distribution_name(requirement)

    if not name:
        return True

    try:
        importlib.metadata.distribution(name)
        return True
    except importlib.metadata.PackageNotFoundError:
        pass

    candidates = {
        name,
        name.replace('-', '_'),
        IMPORT_NAMES.get(name.lower(), name),
    }

    for candidate in candidates:
        try:
            importlib.import_module(candidate)
            return True
        except Exception:
            continue

    return False


def top_level_imports(path):
    with open(path, encoding='utf-8') as handle:
        source = handle.read()

    try:
        tree = ast.parse(source, path)
    except SyntaxError as error:
        return set(), str(error)

    modules = set()

    for node in tree.body:
        if isinstance(node, ast.Import):
            for alias in node.names:
                modules.add(alias.name.split('.')[0])

        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            modules.add(node.module.split('.')[0])

    return modules, None


def read_manifest(path):
    with open(path, encoding='utf-8') as handle:
        return ast.literal_eval(handle.read())


def check_addon(addon_path):
    addon = os.path.basename(addon_path)
    problems = []

    try:
        manifest = read_manifest(os.path.join(addon_path, '__manifest__.py'))
    except Exception as error:
        return [f'{addon}: unreadable manifest ({error})']

    # Declared python dependencies
    external_dependencies = manifest.get('external_dependencies') or {}

    for requirement in external_dependencies.get('python', []):
        if not is_installed(requirement):
            problems.append(f'{addon}: external dependency {requirement!r} is not installed')

    # Imports that run when Odoo loads the addon
    for filename in IMPORTED_FILES:
        path = os.path.join(addon_path, filename)

        if not os.path.isfile(path):
            continue

        modules, error = top_level_imports(path)

        if error:
            problems.append(f'{addon}/{filename}: {error}')
            continue

        for module in sorted(modules):
            if module in BUILTIN_MODULES:
                continue

            # The addon's own packages
            if os.path.isdir(os.path.join(addon_path, module)) or os.path.isfile(os.path.join(addon_path, f'{module}.py')):
                continue

            try:
                importlib.import_module(module)
            except Exception as error:
                problems.append(f'{addon}/{filename}: import {module} fails ({error})')

    return problems


def find_addons(directories):
    for directory in directories:
        if not os.path.isdir(directory):
            continue

        for name in sorted(os.listdir(directory)):
            addon_path = os.path.join(directory, name)

            if os.path.isfile(os.path.join(addon_path, '__manifest__.py')):
                yield addon_path


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(description='Check that every addon has its python dependencies installed')
    arg_parser.add_argument('directories', nargs='*', default=['/volumes/extra_addons'])
    arg_parser.add_argument('--odoo-path', type=str, default='/odoo')
    args = arg_parser.parse_args()

    # Some packages import odoo.fields when they load
    sys.path.insert(0, args.odoo_path)

    try:
        import odoo.api
        import odoo.fields
        import odoo.models
    except Exception:
        pass

    checked = 0
    problems = []

    for addon_path in find_addons(args.directories):
        checked += 1
        problems.extend(check_addon(addon_path))

    print(f'Checked {checked} addon(s) in {", ".join(args.directories)}')

    if problems:
        print('Missing python dependencies, add them to the Dockerfile:')

        for problem in problems:
            print(f'  - {problem}')

        sys.exit(1)

    print('All python dependencies are installed')
