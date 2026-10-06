"""Data-only revision 3; preserve the entire revision-2 pack byte-for-byte.

Usage: python3 tool/build_5000_foods.py USDA_SR_LEGACY_ZIP
Does not alter compiled App seeds, App version, or earlier JSON packages.
"""
from pathlib import Path
import collections
import csv
import hashlib
import importlib.util
import io
import json
import math
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_SHA256 = 'b80817294b8850530aaedf2e515c02593b1824f763a0ff356e5c2081643e6fd0'
FIELDS = {'kcal100': '1008', 'protein100': '1003', 'fat100': '1004', 'carb100': '1005'}


def key(name):
    return re.sub(r'\s+', ' ', name.strip().lower())


def main(archive):
    archive = Path(archive)
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == ARCHIVE_SHA256
    paths = [ROOT / 'food-packs/common-foods.json', ROOT / 'food-packs/common-foods-1000.json',
             ROOT / 'food-packs/common-foods-1000.sources.json']
    before = {p: p.read_bytes() for p in paths}
    previous = json.loads(before[paths[1]])
    source = json.loads(before[paths[2]])
    assert len(previous['foods']) == 1000 and previous['revision'] == 2
    spec = importlib.util.spec_from_file_location('previous_generator', ROOT / 'tool/build_1000_foods.py')
    old = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(old)
    categories = {**old.CATEGORIES, 17: 'protein', 21: 'dish', 24: 'dish', 25: 'dish'}
    fallback = {1: '乳蛋食品', 2: '香辛料', 4: '食用油脂', 5: '禽肉', 6: '汤汁酱料',
                7: '加工肉类', 8: '谷物麦片', 9: '水果', 10: '猪肉', 11: '蔬菜',
                12: '坚果种子', 13: '牛肉', 14: '饮料', 15: '水产', 16: '豆类',
                17: '肉类', 18: '烘焙食品', 19: '甜食', 20: '谷物面食',
                21: '快餐', 22: '混合菜肴', 23: '零食', 24: '地方食物', 25: '餐厅食品'}
    labels = {**old.LABELS, 'lamb': '羊肉', 'veal': '小牛肉', 'game meat': '野味肉类',
              'soybeans': '大豆', 'frozen novelties': '冷冻甜品', 'fast food': '快餐',
              'fast foods': '快餐', 'restaurant': '餐厅食品', 'seaweed': '海藻',
              'margarine-like': '类人造黄油', 'ostrich': '鸵鸟肉', 'emu': '鸸鹋肉'}
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None

        def rows(name):
            names = [n for n in z.namelist() if n.endswith('/' + name)]
            assert len(names) == 1
            return list(csv.DictReader(io.StringIO(z.read(names[0]).decode('utf-8'))))

        foods = rows('food.csv')
        source_categories = {r['id']: r['description'] for r in rows('food_category.csv')}
        units = {r['id']: r['unit_name'] for r in rows('nutrient.csv')}
        assert units['1008'] == 'KCAL' and all(units[n] == 'G' for n in ['1003', '1004', '1005'])
        nutrients = collections.defaultdict(dict)
        for row in rows('food_nutrient.csv'):
            if row['nutrient_id'] in FIELDS.values() and row['amount']:
                value = float(row['amount'])
                slot = nutrients[row['fdc_id']]
                assert row['nutrient_id'] not in slot or slot[row['nutrient_id']] == value
                slot[row['nutrient_id']] = value
    ids = {f['id'] for f in previous['foods']}
    names = {key(f['name']) for f in previous['foods']}
    groups = collections.defaultdict(lambda: collections.defaultdict(list))
    for f in foods:
        gid = int(f['food_category_id'])
        if gid not in categories or 'usda-sr-' + f['fdc_id'] in ids:
            continue  # exclude infant foods and non-food control material categories
        values = nutrients[f['fdc_id']]
        if set(values) != set(FIELDS.values()) or not all(math.isfinite(v) for v in values.values()):
            continue  # missing is not zero; no estimated or invented nutrient values
        if not (0 <= values['1008'] <= 900 and all(0 <= values[n] <= 100 for n in ['1003', '1004', '1005'])):
            continue
        desc = f['description']
        parts = desc.lower().split(', ')
        root = parts[0]
        subject = labels.get(root, old.GENERIC_DETAILS.get(root, fallback[gid]))
        if root in old.GENERIC_DETAILS and len(parts) > 1:
            matched = next((v for k, v in sorted(old.DETAILS.items(), key=lambda x: (-len(x[0]), x[0]))
                            if parts[1].startswith(k)), None)
            subject = matched or subject
        name = subject + ' · ' + desc
        if len(name.encode('utf-16-le')) // 2 > 120 or key(name) in names:
            continue  # retain complete species/cut/preparation/brand descriptions, never truncate
        category = categories[gid]
        if root in {'egg', 'eggs', 'egg substitute'}:
            category = 'protein'
        if gid == 9 and any(w in root for w in ['juice', 'nectar']):
            category = 'drink'
        if gid == 16 and root.startswith(('soymilk', 'soy milk')):
            category = 'drink'
        if gid == 18 and root in {'cookies', 'cookie', 'cake', 'muffin', 'muffins', 'doughnuts', 'danish pastry', 'pie'}:
            category = 'snack'
        bucket = root + (':' + parts[1] if len(parts) > 1 else '')
        rank = (len(desc), 'raw' not in desc.lower(), int(f['fdc_id']))
        groups[gid][bucket].append((rank, f, name, category))

    # Interleave source groups and subject buckets. Avoid filling the library
    # with a single meat cut or many variants of the first alphabetic subject.
    queues = {}
    for gid in sorted(groups):
        buckets = [sorted(values) for _, values in sorted(groups[gid].items())]
        queue = []
        for depth in range(max(map(len, buckets))):
            queue.extend(b[depth] for b in buckets if depth < len(b))
        queues[gid] = collections.deque(queue)
    additions = []
    records = []
    while len(additions) < 4000:
        progressed = False
        for gid, queue in queues.items():
            if not queue:
                continue
            _, f, name, category = queue.popleft()
            if key(name) in names:
                continue
            values = {field: nutrients[f['fdc_id']][nutrient] for field, nutrient in FIELDS.items()}
            row = dict(id='usda-sr-' + f['fdc_id'], name=name, category=category, **values,
                       brand=None, servingDesc='100 克', servingGrams=100.0)
            additions.append(row)
            names.add(key(name))
            records.append(dict(id=row['id'], fdc_id=int(f['fdc_id']), name=name,
                                description=f['description'], usda_category=source_categories[f['food_category_id']],
                                publication_date=f['publication_date'], category=category, **values,
                                source_url='https://fdc.nal.usda.gov/food-details/' + f['fdc_id'] + '/nutrients'))
            progressed = True
            if len(additions) == 4000:
                break
        assert progressed, 'Insufficient distinct, complete, schema-valid USDA records'
    result = {**previous, 'revision': 3, 'title': '常见食物库 · 5000 条', 'foods': previous['foods'] + additions}
    assert len(result['foods']) == len({f['id'] for f in result['foods']}) == len({key(f['name']) for f in result['foods']}) == 5000
    assert result['foods'][:1000] == previous['foods']
    provenance = {**source, 'added_rows': 4763, 'previous_revision': 2, 'revision': 3,
                  'previous_rows_preserved': 1000, 'new_rows_this_revision': 4000,
                  'previous_file_sha256': hashlib.sha256(before[paths[1]]).hexdigest(),
                  'naming_note': 'Chinese subject or category keyword + intact USDA English description; generic category labels are not full translations.',
                  'added_usda_records': source['added_usda_records'] + records}
    for name, data in [('common-foods-5000.json', result), ('common-foods-5000.sources.json', provenance)]:
        p = ROOT / 'food-packs' / name
        p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        assert p.read_bytes() and json.loads(p.read_text()) == data
    assert (ROOT / 'food-packs/common-foods-5000.json').stat().st_size < 5 * 1024 * 1024
    assert all(p.read_bytes() == b for p, b in before.items())
    print('PACK_REVISION=3;PREVIOUS1000_UNCHANGED;NEW_REAL_USDA=4000;TOTAL=5000')
    print('CATEGORY_COUNTS=' + json.dumps(dict(collections.Counter(f['category'] for f in result['foods']))))


if __name__ == '__main__':
    main(sys.argv[1])
