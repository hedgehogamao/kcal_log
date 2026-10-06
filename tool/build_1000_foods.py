"""Reproduce the data-only expansion from USDA's SR Legacy CSV ZIP.

Usage: python3 tool/build_1000_foods.py USDA_ZIP
The original 237-row common-foods.json is input only and remains unchanged.
"""
from pathlib import Path
import collections
import csv
import hashlib
import io
import json
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
QUOTAS = {1: 60, 2: 15, 4: 15, 5: 30, 6: 30, 7: 20, 8: 25,
          9: 85, 10: 30, 11: 100, 12: 40, 13: 25, 14: 35, 15: 55,
          16: 45, 18: 33, 19: 30, 20: 45, 22: 25, 23: 20}
assert sum(QUOTAS.values()) == 763
CATEGORIES = {1: 'dairy', 2: 'other', 4: 'other', 5: 'protein',
              6: 'dish', 7: 'protein', 8: 'staple', 9: 'fruit',
              10: 'protein', 11: 'vegetable', 12: 'snack', 13: 'protein',
              14: 'drink', 15: 'protein', 16: 'protein', 18: 'staple',
              19: 'snack', 20: 'staple', 22: 'dish', 23: 'snack'}

# Chinese subject labels aid local search; retain the EXACT full English food
# description alongside them to avoid losing species, cut or preparation state.
LABELS = dict(line.split('=', 1) for line in '''milk=牛奶
cheese=奶酪
cheese spread=奶酪涂抹酱
cheese food=加工奶酪
cheese product=奶酪制品
cream=奶油
cream substitute=奶油替代品
sour cream=酸奶油
yogurt=酸奶
kefir=开菲尔发酵乳
whey=乳清
egg=禽蛋
eggs=禽蛋
egg substitute=代蛋制品
butter=黄油
butter oil=无水黄油
ice cream=冰淇淋
milk shakes=奶昔
eggnog=蛋奶饮料
whipped topping=打发奶油配料
spices=香辛料
vinegar=食醋
salt=食盐
mustard=芥末酱
basil=罗勒
thyme=百里香
rosemary=迷迭香
parsley=欧芹
peppermint=胡椒薄荷
spearmint=留兰香薄荷
horseradish=辣根
capers=刺山柑
oil=食用油
salad dressing=沙拉酱
mayonnaise=蛋黄酱
shortening=起酥油
lard=猪油
margarine=人造黄油
chicken=鸡肉
turkey=火鸡肉
duck=鸭肉
goose=鹅肉
quail=鹌鹑肉
guinea hen=珍珠鸡肉
poultry=禽肉
soup=汤品
sauce=酱汁
gravy=肉汁
sausage=香肠
sausages=香肠
bologna=博洛尼亚香肠
frankfurter=法兰克福香肠
salami=萨拉米香肠
ham=火腿
bacon=培根
luncheon meat=午餐肉
pepperoni=意式辣香肠
cereals=谷物麦片
cereals ready-to-eat=即食谷物麦片
cereals ready-to eat=即食谷物麦片
apples=苹果
apple juice=苹果汁
applesauce=苹果酱
apricots=杏
apricot nectar=杏汁饮料
avocados=牛油果
bananas=香蕉
blackberries=黑莓
blueberries=蓝莓
boysenberries=波森莓
breadfruit=面包果
carambola=杨桃
cherries=樱桃
cherry juice=樱桃汁
clementines=克莱门氏柑橘
cranberries=蔓越莓
cranberry juice=蔓越莓汁
cranberry sauce=蔓越莓酱
currants=醋栗
dates=椰枣
durian=榴莲
elderberries=接骨木莓
feijoa=斐济果
figs=无花果
fruit cocktail=混合水果
fruit salad=水果沙拉
goji berries=枸杞
gooseberries=鹅莓
grapefruit=葡萄柚
grapefruit juice=葡萄柚汁
grapes=葡萄
grape juice=葡萄汁
guavas=番石榴
guava nectar=番石榴汁饮料
jackfruit=菠萝蜜
java-plum=爪哇蒲桃
jujube=枣
kiwifruit=猕猴桃
kumquats=金桔
lemons=柠檬
lemon juice=柠檬汁
lemon juice from concentrate=浓缩还原柠檬汁
lemon peel=柠檬皮
limes=青柠
lime juice=青柠汁
litchis=荔枝
loganberries=罗甘莓
longans=龙眼
loquats=枇杷
mango=芒果
mangos=芒果
mango nectar=芒果汁饮料
mangosteen=山竹
melons=甜瓜
mulberries=桑葚
nectarines=油桃
olives=橄榄
oranges=橙子
orange juice=橙汁
orange peel=橙皮
papaya=木瓜
papayas=木瓜
papaya nectar=木瓜汁饮料
passion-fruit=百香果
passion-fruit juice=百香果汁
peaches=桃
peach nectar=桃汁饮料
pears=梨
pear nectar=梨汁饮料
persimmons=柿子
pineapple=菠萝
pineapple juice=菠萝汁
plantains=大蕉
plums=李子与西梅
pomegranates=石榴
pomegranate juice=石榴汁
prickly pears=仙人掌果
prunes=西梅干
prune juice=西梅汁
prune puree=西梅泥
pummelo=柚子
quinces=榅桲
raisins=葡萄干
rambutan=红毛丹
raspberries=覆盆子
rhubarb=食用大黄
roselle=洛神花
strawberries=草莓
tamarinds=罗望子
tamarind nectar=罗望子汁饮料
tangerines=橘子
tangerine juice=橘子汁
watermelon=西瓜
alfalfa seeds=苜蓿芽
amaranth leaves=苋菜叶
artichokes=洋蓟
arugula=芝麻菜
asparagus=芦笋
balsam-pear (bitter gourd)=苦瓜
bamboo shoots=竹笋
beans=菜豆
beets=甜菜
beet greens=甜菜叶
broadbeans=蚕豆
broccoli=西兰花
broccoli raab=西兰花苗
brussels sprouts=抱子甘蓝
burdock root=牛蒡根
cabbage=卷心菜
carrots=胡萝卜
carrot=胡萝卜
cassava=木薯
cauliflower=菜花
celeriac=根芹菜
celery=芹菜
celtuce=莴笋
chard=瑞士甜菜
chayote=佛手瓜
chicory=菊苣
chicory greens=菊苣叶
chicory roots=菊苣根
chives=细香葱
chrysanthemum=茼蒿
chrysanthemum leaves=茼蒿叶
collards=羽衣甘蓝叶
coriander (cilantro) leaves=香菜叶
corn=玉米
cowpeas=豇豆
cowpeas (blackeyes)=黑眼豆
cress=独行菜
cucumber=黄瓜
dandelion greens=蒲公英叶
edamame=毛豆
eggplant=茄子
endive=苦苣
escarole=宽叶苦苣
fennel=茴香
garlic=大蒜
ginger root=生姜
gourd=葫芦瓜
grape leaves=葡萄叶
hearts of palm=棕榈心
jerusalem-artichokes=菊芋
jew's ear=木耳
kale=羽衣甘蓝
kohlrabi=苤蓝
leeks=西洋韭葱
lentils=小扁豆
lettuce=生菜
lima beans=利马豆
lotus root=莲藕
mountain yam=山药
mung beans=绿豆芽
mushroom=蘑菇
mushrooms=蘑菇
mustard greens=芥菜叶
mustard spinach=小松菜
okra=秋葵
onions=洋葱
parsnips=欧防风根
peas=豌豆
peas and carrots=豌豆胡萝卜
peas and onions=豌豆洋葱
peppers=椒类
pickles=腌菜
potatoes=土豆
potato flour=土豆粉
potato salad=土豆沙拉
pumpkin=南瓜
pumpkin leaves=南瓜叶
pumpkin flowers=南瓜花
purslane=马齿苋
radicchio=红叶菊苣
radishes=萝卜
rutabagas=芜菁甘蓝
sauerkraut=酸菜
seaweed=海藻
shallots=红葱头
soybeans=大豆
spinach=菠菜
squash=瓜类
sweet potato=红薯
sweet potatoes=红薯
sweet potato leaves=红薯叶
taro=芋头
taro leaves=芋叶
taro shoots=芋茎
tomatillos=酸浆果
tomatoes=番茄
tomato products=番茄制品
tomato sauce=番茄酱汁
turnips=芜菁
turnip greens=芜菁叶
vegetables=混合蔬菜
wasabi=山葵
waterchestnuts=荸荠
watercress=西洋菜
water convolvulus=空心菜
waxgourd=冬瓜
winged beans=四棱豆
yam=薯蓣
yardlong bean=长豇豆
beef=牛肉
pork=猪肉
water=饮用水
lemonade=柠檬饮料
limeade=青柠饮料
carbonated beverage=碳酸饮料
beverages=饮料
alcoholic beverage=酒类
alcoholic beverages=酒类
fish=鱼类
salmon=三文鱼
mollusks=贝类
crustaceans=甲壳类水产
jellyfish=海蜇
frog legs=蛙腿
tofu=豆腐
tofu yogurt=豆乳酸奶
soybean=大豆
soy flour=豆粉
soy meal=脱脂豆粕
soymilk=豆奶
soymilk (all flavors)=豆奶
peanut butter=花生酱
peanuts=花生
peanut flour=花生粉
broadbeans (fava beans)=蚕豆
chickpeas (garbanzo beans=鹰嘴豆
chickpea flour (besan)=鹰嘴豆粉
refried beans=煎炒豆泥
tempeh=天贝
miso=味噌
natto=纳豆
okara=豆渣
hummus=鹰嘴豆泥
falafel=炸豆丸
vermicelli=粉丝
soy sauce=酱油
soy sauce made from soy and wheat (shoyu)=日式酱油
soy sauce made from soy (tamari)=日式豆酱油
veggie burgers or soyburgers=素汉堡饼
waffles=华夫饼
waffle=华夫饼
pie crust=派皮
pie=派
bread=面包
crackers=薄脆饼干
bagels=贝果
cream puff=奶油泡芙
tortillas=墨西哥薄饼
pancakes=煎饼
pancakes plain=原味煎饼
muffin=玛芬蛋糕
muffins=玛芬蛋糕
cake=蛋糕
garlic bread=蒜香面包
focaccia=佛卡夏面包
cookies=曲奇饼干
cookie=曲奇饼干
rolls=小面包
biscuits=美式松饼
puff pastry=酥皮
croutons=面包丁
danish pastry=丹麦酥
doughnuts=甜甜圈
french toast=法式吐司
english muffins=英式玛芬面包
croissants=可颂
phyllo dough=千层酥皮
sweet rolls=甜面包
taco shells=塔可饼壳
candies=糖果
baking chocolate=烘焙巧克力
ice creams=冰淇淋
desserts=甜品
sherbet=果汁冰糕
syrups=糖浆
syrup=糖浆
puddings=布丁
pudding=布丁
jams=果酱
jams and preserves=果酱
jellies=果冻
sweeteners=甜味剂
sweetener=甜味剂
cocoa=可可粉
chocolate=巧克力
sugars=糖类
sugar=糖
honey=蜂蜜
marmalade=柑橘果酱
molasses=糖蜜
frozen yogurts=冷冻酸奶
gelatin desserts=果冻甜品
frostings=糖霜
vital wheat gluten=小麦面筋粉
cornmeal=玉米粉
millet=小米
oat bran=燕麦麸
quinoa=藜麦
rice=大米
rye grain=黑麦粒
rye flour=黑麦粉
triticale flour=小黑麦粉
wheat=小麦
wheat germ=小麦胚芽
wheat flour=小麦粉
wheat flours=小麦粉
wild rice=菰米
rice flour=米粉
pasta=意大利面
macaroni=通心粉
noodles=面条
spaghetti=意大利细面
rice noodles=米线
teff=苔麸
corn grain=玉米粒
corn flour=玉米面粉
semolina=粗粒小麦粉
sorghum flour=高粱粉
cornstarch=玉米淀粉
couscous=库斯库斯
hominy=碱处理玉米
rice bran=米糠
sorghum grain=高粱粒
tapioca=木薯粉
triticale=小黑麦
wheat bran=小麦麸
barley flour or meal=大麦粉
barley malt flour=大麦芽粉
oat flour=燕麦粉
spelt=斯佩耳特小麦
barley=大麦
buckwheat=荞麦
bulgur=布格麦
corn bran=玉米麸
amaranth grain=籽粒苋
arrowroot flour=竹芋粉
buckwheat groats=荞麦粒
buckwheat flour=荞麦粉
millet flour=小米粉
rice and vermicelli mix=大米粉丝混合餐
pasta mix=意面混合餐
yellow rice with seasoning=调味黄米饭
pizza rolls=披萨卷
spanish rice mix=西班牙风味米饭
lasagna=千层意面
turnover=馅饼
rice mix=混合米饭
salisbury steak with gravy=肉汁汉堡牛排
macaroni and cheese=奶酪通心粉
taquitos=墨西哥小卷饼
potsticker or wonton=锅贴或馄饨
macaroni or noodles with cheese=奶酪面食
dumpling=饺子
spaghetti with meat sauce=肉酱意面
beef macaroni with tomato sauce=番茄牛肉通心粉
turkey pot pie=火鸡肉派
beef pot pie=牛肉派
chicken pot pie=鸡肉派
tortellini=意式环形饺
chili con carne with beans=豆类辣炖肉
chili with beans=辣炖豆
chili=辣炖菜
spaghetti=意大利细面
pasta with tomato sauce=番茄酱意面
lasagna with meat & sauce=肉酱千层意面
lasagna with meat sauce=肉酱千层意面
burrito=墨西哥卷饼
egg rolls=炸春卷
ravioli=意式方饺
beef stew=炖牛肉
rice bowl with chicken=鸡肉盖饭
potato salad with egg=鸡蛋土豆沙拉
pulled pork in barbecue sauce=烤肉酱手撕猪肉
corn dogs=玉米热狗
chicken tenders=鸡柳
snacks=零食
snack=零食
breakfast bar=早餐谷物棒
breakfast bars=早餐谷物棒
granola bar=格兰诺拉谷物棒
rice cake=米饼
popcorn=爆米花
tortilla chips=玉米脆片
cheese puffs and twists=奶酪膨化零食
pretzels=椒盐脆饼
potato chips=薯片
rice crackers=米脆饼
rice and wheat cereal bar=米麦谷物棒
milk and cereal bar=奶味谷物棒'''.splitlines())

DETAILS = dict(line.split('=', 1) for line in '''almonds=杏仁
almond butter=杏仁酱
cashew nuts=腰果
cashews=腰果
cashew butter=腰果酱
chestnuts=栗子
coconut meat=椰肉
coconut milk=椰奶
hazelnuts or filberts=榛子
macadamia nuts=夏威夷果
mixed nuts=混合坚果
pecans=碧根果
pine nuts=松子
pistachio nuts=开心果
walnuts=核桃
brazilnuts=巴西坚果
flaxseed=亚麻籽
chia seeds=奇亚籽
sunflower seed=葵花籽
sunflower seeds=葵花籽
pumpkin and squash seed=南瓜籽
pumpkin and squash seeds=南瓜籽
sesame seed=芝麻
sesame seeds=芝麻
sesame butter=芝麻酱
lotus seeds=莲子
watermelon seed=西瓜籽
cod=鳕鱼
salmon=三文鱼
tuna=金枪鱼
trout=鳟鱼
mackerel=鲭鱼
sardine=沙丁鱼
herring=鲱鱼
halibut=大比目鱼
haddock=黑线鳕
anchovy=凤尾鱼
carp=鲤鱼
catfish=鲶鱼
eel=鳗鱼
perch=鲈形鱼
tilapia=罗非鱼
pollock=明太鱼
flounder and sole=鲽鱼与鳎鱼
bass=鲈鱼
swordfish=剑鱼
shrimp=虾
crab=蟹
lobster=龙虾
crayfish=小龙虾
clam=蛤蜊
oyster=牡蛎
mussel=贻贝
scallop=扇贝
squid=鱿鱼
octopus=章鱼
abalone=鲍鱼
bay leaf=月桂叶
caraway seed=葛缕子籽
cardamom=小豆蔻
celery seed=芹菜籽
coriander leaf=香菜叶
coriander seed=芫荽籽
cumin seed=孜然
curry powder=咖喱粉
ginger=姜粉
pepper=胡椒与辣椒
cinnamon=肉桂
garlic powder=蒜粉
onion powder=洋葱粉
paprika=红椒粉
turmeric=姜黄粉
nutmeg=肉豆蔻
cloves=丁香
basil=罗勒
rosemary=迷迭香
thyme=百里香
coffee=咖啡
tea=茶
almond milk=杏仁饮料
soy milk=豆奶
coconut milk=椰奶
rice milk=米奶
carbonated=碳酸饮料
chocolate=巧克力饮料
orange juice drink=橙汁饮料
apple juice drink=苹果汁饮料
grape juice drink=葡萄汁饮料
cranberry=蔓越莓饮料
wine=葡萄酒
beer=啤酒
rice (sake)=清酒
whiskey=威士忌
vodka=伏特加
rum=朗姆酒
gin=杜松子酒'''.splitlines())

GENERIC_DETAILS = {'nuts': '坚果', 'seeds': '种子类食物',
                   'spices': '香辛料', 'fish': '鱼类',
                   'mollusks': '贝类', 'crustaceans': '甲壳类水产',
                   'beverages': '饮料', 'alcoholic beverage': '酒类',
                   'alcoholic beverages': '酒类', 'snacks': '零食',
                   'cereals ready-to-eat': '即食麦片'}


def main(archive):
    legacy_path = ROOT / 'food-packs/common-foods.json'
    original = legacy_path.read_bytes()
    legacy = json.loads(original)
    assert len(legacy['foods']) == 237 and legacy['revision'] == 1
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        def rows(name):
            path = next(n for n in z.namelist() if n.endswith('/'+name))
            return list(csv.DictReader(io.StringIO(z.read(path).decode('utf-8'))))
        foods = rows('food.csv')
        categories = {r['id']: r['description'] for r in rows('food_category.csv')}
        nutrients = collections.defaultdict(dict)
        for n in rows('food_nutrient.csv'):
            if n['nutrient_id'] in {'1008', '1003', '1004', '1005'} and n['amount']:
                nutrients[n['fdc_id']][n['nutrient_id']] = float(n['amount'])
        units = {n['id']: n['unit_name'] for n in rows('nutrient.csv')}
        assert units['1008'] == 'KCAL'
        assert all(units[n] == 'G' for n in ['1003', '1004', '1005'])

    groups = collections.defaultdict(lambda: collections.defaultdict(list))
    for f in foods:
        gid = int(f['food_category_id']); desc = f['description']
        # No shortening/truncating descriptive food names. Reject longer names
        # rather than silently dropping important preparation/cut information.
        if gid not in QUOTAS or len(desc) > 96:
            continue
        parts = desc.lower().split(', '); root = parts[0]
        if root not in LABELS and root not in GENERIC_DETAILS:
            continue  # excludes brand-name and poorly labelled products
        values = nutrients[f['fdc_id']]
        if set(values) != {'1008', '1003', '1004', '1005'}:
            continue  # missing is not zero; no fabricated/derived macros
        if not (0 <= values['1008'] <= 900 and all(0 <= values[n] <= 100 for n in ['1003', '1004', '1005'])):
            continue
        subject = LABELS.get(root, GENERIC_DETAILS.get(root))
        bucket = root
        if root in GENERIC_DETAILS and len(parts) > 1:
            detail = parts[1]
            matched = next((v for k, v in sorted(DETAILS.items(), key=lambda x: -len(x[0])) if detail.startswith(k)), None)
            if root in {'nuts', 'seeds', 'spices', 'fish', 'mollusks', 'crustaceans'} and not matched:
                continue
            subject = matched or subject
            bucket = root+':'+detail
        elif root in {'pork', 'beef', 'chicken', 'turkey', 'duck'} and len(parts)>1:
            bucket = root+':'+parts[1]
        name = subject+' · '+desc
        if len(name)>120:
            continue
        category=CATEGORIES[gid]
        if gid == 16 and root == 'mung beans':
            subject='绿豆'
            name=subject+' · '+desc
        if root in {'egg', 'eggs', 'egg substitute'}: category='protein'
        if gid == 9 and any(w in root for w in ['juice','nectar']): category='drink'
        if gid == 16 and root.startswith('soymilk'): category='drink'
        if gid == 18 and root in {'cookies','cookie','cake','muffin','muffins','doughnuts','danish pastry','pie'}: category='snack'
        rank=(len(desc), 'raw' not in desc.lower(), int(f['fdc_id']))
        groups[gid][bucket].append((rank,f,name,category))

    chosen=[]
    for gid,quota in QUOTAS.items():
        buckets=[sorted(b) for _,b in sorted(groups[gid].items())]
        available=sum(map(len,buckets))
        assert available >= quota, (gid, quota, available)
        picked=[]
        # Round-robin across subjects, not dozens of nearly identical beef cuts
        # or a run of canned apple entries in alphabetic source-file order.
        depth=0
        while len(picked)<quota:
            for b in buckets:
                if depth<len(b): picked.append(b[depth])
                if len(picked)==quota: break
            depth+=1
        chosen+=picked

    additions=[]; provenance=[]
    for _,f,name,category in chosen:
        n=nutrients[f['fdc_id']]
        food=dict(id='usda-sr-'+f['fdc_id'],name=name,category=category,
                  kcal100=n['1008'],protein100=n['1003'],fat100=n['1004'],carb100=n['1005'],
                  brand=None,servingDesc='100 克',servingGrams=100.0)
        additions.append(food)
        provenance.append(dict(id=food['id'],fdc_id=int(f['fdc_id']),name=name,
                               description=f['description'],usda_category=categories[f['food_category_id']],
                               publication_date=f['publication_date'],category=category,
                               kcal100=n['1008'],protein100=n['1003'],fat100=n['1004'],carb100=n['1005'],
                               source_url='https://fdc.nal.usda.gov/food-details/'+f['fdc_id']+'/nutrients'))
    allfoods=legacy['foods']+additions
    assert len(allfoods)==1000
    assert len({f['id'] for f in allfoods})==1000
    assert len({re.sub(r'\s+',' ',f['name'].lower().strip()) for f in allfoods})==1000
    pack={**legacy,'revision':2,'title':'常见食物库 · 1000 条','foods':allfoods}
    def write(path,data):
        path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    write(ROOT/'food-packs/common-foods-1000.json',pack)
    write(ROOT/'food-packs/common-foods-1000.sources.json',dict(
        source='USDA FoodData Central SR Legacy (final release April 2018)',
        download_url='https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip',
        archive_sha256=hashlib.sha256(Path(archive).read_bytes()).hexdigest(),
        documentation_url='https://fdc.nal.usda.gov/data-documentation',
        units={'kcal100':'kcal/100g','protein100':'g/100g','fat100':'g/100g','carb100':'g/100g'},
        nutrient_ids={'kcal100':1008,'protein100':1003,'fat100':1004,'carb100':1005},
        legacy_rows=237,legacy_file_sha256=hashlib.sha256(original).hexdigest(),
        added_rows=763,added_usda_records=provenance))
    # Dart part uses the same exact records. No runtime network/JSON read or
    # asset loading is required for new-install seeding on any Flutter platform.
    lines=["// Generated by tool/build_1000_foods.py; USDA SR Legacy per 100g.",
           "// Chinese search subject + intact English descriptor; see sources JSON.",
           "part of 'seed_data.dart';",'',
           'final kExpandedSeedFoods = <(SeedFood, FoodCategory, String)>[']
    for f in additions:
        q=lambda v: json.dumps(v,ensure_ascii=False).replace('$',r'\$')
        lines.append('  (_s('+', '.join([q(f['name']),str(f['kcal100']),str(f['protein100']),str(f['fat100']),str(f['carb100'])])+", servingDesc: '100 克', servingGrams: 100), FoodCategory."+f['category']+', '+q(f['id'])+'),')
    lines+= ['];','']
    (ROOT/'lib/data/seed_data_expanded.dart').write_text('\n'.join(lines),encoding='utf-8')
    assert legacy_path.read_bytes()==original
    print('PACK_REVISION=2;LEGACY_UNCHANGED=237;ADDED_REAL_USDA=763;TOTAL=1000')
    print('CATEGORY_COUNTS='+json.dumps(dict(collections.Counter(f['category'] for f in allfoods))))


if __name__ == '__main__':
    main(Path(sys.argv[1]))
