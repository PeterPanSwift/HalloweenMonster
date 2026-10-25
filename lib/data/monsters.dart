/// 圖片來源資訊（全部取自 Wikimedia Commons 的公有領域或 CC 授權作品）。
class ImageCredit {
  const ImageCredit({
    required this.title,
    required this.artist,
    required this.license,
    required this.url,
  });

  final String title;
  final String artist;
  final String license;
  final String url;
}

class Monster {
  const Monster({
    required this.id,
    required this.name,
    required this.englishName,
    required this.origin,
    required this.scareLevel,
    required this.tagline,
    required this.story,
    required this.powers,
    required this.weaknesses,
    required this.funFact,
    required this.credit,
  });

  final String id;
  final String name;
  final String englishName;
  final String origin;

  /// 1 ~ 5 顆骷髏的恐怖指數。
  final int scareLevel;
  final String tagline;
  final String story;
  final List<String> powers;
  final List<String> weaknesses;
  final String funFact;
  final ImageCredit credit;

  String get image => 'assets/monsters/$id.jpg';
}

const monsters = <Monster>[
  Monster(
    id: 'jack_o_lantern',
    name: '南瓜燈傑克',
    englishName: "Jack-o'-Lantern",
    origin: '愛爾蘭民間傳說',
    scareLevel: 2,
    tagline: '提著鬼火、在人間遊蕩的吝嗇鬼',
    story:
        '傳說吝嗇鬼傑克兩度戲弄惡魔，死後天堂不收、地獄也不要，'
        '只能把一塊炭火放進挖空的蕪菁裡當燈籠，在黑夜中永遠遊蕩。'
        '愛爾蘭移民來到美國後，改用更大、更好雕刻的南瓜，'
        '南瓜燈從此成為萬聖節最具代表性的象徵。',
    powers: ['在黑夜中發出詭異光芒', '為迷路的靈魂指引方向', '嚇跑想闖進家門的惡靈'],
    weaknesses: ['天一亮就會熄滅', '放太久會發霉變軟'],
    funFact: '最早的「傑克燈籠」其實是用蕪菁和馬鈴薯雕成的！',
    credit: ImageCredit(
      title: "Jack-o'-Lantern 2003-10-31.jpg",
      artist: 'Toby Ord',
      license: 'CC BY-SA 2.5',
      url:
          'https://commons.wikimedia.org/wiki/File:Jack-o%27-Lantern_2003-10-31.jpg',
    ),
  ),
  Monster(
    id: 'vampire',
    name: '吸血鬼',
    englishName: 'Vampire',
    origin: '東歐民間傳說',
    scareLevel: 4,
    tagline: '在月光下甦醒的不死貴族',
    story:
        '白天沉睡在棺材裡，夜晚甦醒後吸食活人的鮮血來維持永恆的生命。'
        '1897 年布拉姆・史托克的小說《德古拉》讓吸血鬼伯爵風靡全球；'
        '1922 年的德國默片《諾斯費拉圖》則創造了光頭、尖耳、長指甲的經典恐怖形象。',
    powers: ['變身成蝙蝠或霧氣', '催眠與操控人心', '擁有永恆的生命'],
    weaknesses: ['陽光', '大蒜', '十字架與聖水', '心臟被木樁刺穿'],
    funFact: '傳說吸血鬼在鏡子裡照不出倒影，而且必須受到邀請才能進入別人家。',
    credit: ImageCredit(
      title: 'Nosferatu (1922) - Count Orlok Standing In A Wooden Doorway.png',
      artist: 'F. W. Murnau / Henrik Galeen',
      license: 'Public domain',
      url:
          'https://commons.wikimedia.org/wiki/File:Nosferatu_(1922)_-_Count_Orlok_Standing_In_A_Wooden_Doorway.png',
    ),
  ),
  Monster(
    id: 'werewolf',
    name: '狼人',
    englishName: 'Werewolf',
    origin: '歐洲古老傳說',
    scareLevel: 4,
    tagline: '滿月之夜，人性被狼嚎吞沒',
    story:
        '平時看起來和一般人沒有兩樣，但每逢滿月就會不受控制地變成兇猛的狼。'
        '古希臘神話中，阿卡迪亞國王呂卡翁因為觸怒宙斯而被變成狼，'
        '是最早的狼人故事之一。這幅版畫是德國畫家老盧卡斯・克拉納赫約 1512 年的作品。',
    powers: ['超乎常人的力量與速度', '極度敏銳的嗅覺', '傷口快速癒合'],
    weaknesses: ['銀製子彈或武器', '附子草（狼毒草）'],
    funFact: '「狼化妄想症」的英文 lycanthropy，就是來自國王呂卡翁（Lycaon）的名字。',
    credit: ImageCredit(
      title: 'The Werewolf or the Cannibal MET DP842190.jpg',
      artist: 'Lucas Cranach the Elder',
      license: 'CC0',
      url:
          'https://commons.wikimedia.org/wiki/File:The_Werewolf_or_the_Cannibal_MET_DP842190.jpg',
    ),
  ),
  Monster(
    id: 'frankenstein',
    name: '科學怪人',
    englishName: "Frankenstein's Monster",
    origin: '英國小說（1818）',
    scareLevel: 3,
    tagline: '被閃電喚醒、渴望被愛的孤獨巨人',
    story:
        '瑪麗・雪萊 19 歲時寫下的小說主角。科學家維克多・法蘭克斯坦用屍塊拼湊出巨大的生物，'
        '並以電流賦予它生命，卻因為它醜陋的外表而將它拋棄。'
        '很多人以為「法蘭克斯坦」是怪物的名字，其實那是科學家的姓氏。',
    powers: ['驚人的怪力', '不怕嚴寒', '學習能力極強'],
    weaknesses: ['害怕火焰', '渴望被愛，卻總是被人類排斥'],
    funFact: '原著裡的怪物其實能言善道，還自學閱讀了《失樂園》和《少年維特的煩惱》。',
    credit: ImageCredit(
      title: 'Frontispiece to Frankenstein 1831.jpg',
      artist: 'Theodor von Holst',
      license: 'Public domain',
      url:
          'https://commons.wikimedia.org/wiki/File:Frontispiece_to_Frankenstein_1831.jpg',
    ),
  ),
  Monster(
    id: 'mummy',
    name: '木乃伊',
    englishName: 'Mummy',
    origin: '古埃及',
    scareLevel: 3,
    tagline: '沉睡千年的法老，醒來帶著詛咒',
    story:
        '古埃及人相信靈魂需要完好的肉身才能在來世重生，'
        '因此會把遺體做防腐處理，再一層層包上亞麻布。'
        '後來的小說和電影則想像：被盜墓者打擾的法老木乃伊會甦醒，並對入侵者降下可怕的詛咒。',
    powers: ['法老的詛咒', '操控沙塵暴', '不老不死'],
    weaknesses: ['火焰', '裹布被解開'],
    funFact: '製作一具木乃伊大約需要 70 天，連心臟以外的內臟都要另外保存在「卡諾卜罈」裡。',
    credit: ImageCredit(
      title: 'Egyptian mummies in Ägyptisches Museum Berlin.jpg',
      artist: 'Yair Haklai',
      license: 'CC BY-SA 4.0',
      url:
          'https://commons.wikimedia.org/wiki/File:Egyptian_mummies_in_%C3%84gyptisches_Museum_Berlin.jpg',
    ),
  ),
  Monster(
    id: 'witch',
    name: '女巫',
    englishName: 'Witch',
    origin: '歐洲民間信仰',
    scareLevel: 3,
    tagline: '騎著掃帚劃過月亮的魔法師',
    story:
        '騎著掃帚在夜空中飛行、在大鍋裡熬煮魔藥、施展神秘咒語，身旁總有一隻黑貓相伴。'
        '傳說萬聖夜是女巫們聚集舉行夜宴的日子。'
        '這張可愛的萬聖節明信片來自 20 世紀初，當時寄送節日明信片非常流行。',
    powers: ['騎掃帚飛行', '調製魔藥', '詛咒與預言'],
    weaknesses: ['傳說害怕清水與鹽巴', '掃帚被藏起來就飛不了'],
    funFact: '尖頂帽加掃帚的女巫造型，是在 19 世紀的童書插畫中才逐漸定型的。',
    credit: ImageCredit(
      title:
          'Halloween postcard - DPLA - f567189d6685266387a868a256399742 (page 1).jpg',
      artist: 'Digital Public Library of America',
      license: 'Public domain',
      url:
          'https://commons.wikimedia.org/wiki/File:Halloween_postcard_-_DPLA_-_f567189d6685266387a868a256399742_(page_1).jpg',
    ),
  ),
  Monster(
    id: 'ghost',
    name: '幽靈',
    englishName: 'Ghost',
    origin: '世界各地',
    scareLevel: 3,
    tagline: '心願未了，徘徊在人間的靈魂',
    story:
        '亡者因為未了的心願而滯留人間，飄浮在古堡、老屋與墓園之中。'
        '古凱爾特人相信 10 月 31 日是生者與亡者世界界線最模糊的夜晚，'
        '鬼魂會回到人間——這正是萬聖節的起源。'
        '圖中拖著鐵鍊現身的，是狄更斯《小氣財神》裡的馬利鬼魂（1843 年插畫）。',
    powers: ['穿牆而過', '隱形', '讓房間溫度驟降'],
    weaknesses: ['完成心願後就會安息', '雞啼天亮時必須離開'],
    funFact: '披著白床單的幽靈造型，源自早年人們用白色裹屍布包覆遺體的習俗。',
    credit: ImageCredit(
      title: "Marley's Ghost-John Leech, 1843 (cropped 1).jpg",
      artist: 'John Leech',
      license: 'Public domain',
      url:
          'https://commons.wikimedia.org/wiki/File:Marley%27s_Ghost-John_Leech,_1843_(cropped_1).jpg',
    ),
  ),
  Monster(
    id: 'skeleton',
    name: '骷髏',
    englishName: 'Skeleton',
    origin: '中世紀歐洲・墨西哥',
    scareLevel: 2,
    tagline: '喀啦喀啦，跳著死亡之舞',
    story:
        '中世紀歐洲的「死亡之舞」畫作中，骷髏拉著國王、主教與平民一起跳舞，提醒世人死亡之前人人平等。'
        '墨西哥版畫家波薩達筆下戴著華麗帽子的「卡特里娜」骷髏貴婦，'
        '則成為亡靈節最受歡迎的形象，用幽默的方式紀念逝去的親人。',
    powers: ['拆散後自動重組', '在月光下跳舞', '不需要吃飯睡覺'],
    weaknesses: ['被狗叼走骨頭', '骨頭散落一地就得慢慢拼回去'],
    funFact: '成年人的身體有 206 塊骨頭，但剛出生的嬰兒大約有 300 塊！',
    credit: ImageCredit(
      title: 'Posada2.Catrina.jpeg',
      artist: 'José Guadalupe Posada',
      license: 'Public domain',
      url: 'https://commons.wikimedia.org/wiki/File:Posada2.Catrina.jpeg',
    ),
  ),
  Monster(
    id: 'headless_horseman',
    name: '無頭騎士',
    englishName: 'Headless Horseman',
    origin: '美國小說（1820）',
    scareLevel: 5,
    tagline: '在沉睡谷狂奔，尋找自己的頭',
    story:
        '華盛頓・歐文的《斷頭谷傳說》中，一名騎兵在戰爭中被砲彈打掉了頭。'
        '從此每天夜裡，他都騎著黑馬在沉睡谷奔馳，尋找遺失的頭顱，'
        '還會追趕深夜獨自回家的路人——膽小的教師伊卡博德就是受害者之一。',
    powers: ['高超的騎術', '投擲燃燒的南瓜頭', '在黑夜中來去無蹤'],
    weaknesses: ['無法越過教堂旁的那座橋', '天亮前必須回到墓地'],
    funFact: '愛爾蘭也有類似的無頭騎士傳說「杜拉漢」（Dullahan），他會把自己的頭夾在腋下。',
    credit: ImageCredit(
      title:
          'John Quidor - The Headless Horseman Pursuing Ichabod Crane - Google Art Project.jpg',
      artist: 'John Quidor',
      license: 'Public domain',
      url:
          'https://commons.wikimedia.org/wiki/File:John_Quidor_-_The_Headless_Horseman_Pursuing_Ichabod_Crane_-_Google_Art_Project.jpg',
    ),
  ),
  Monster(
    id: 'banshee',
    name: '報喪女妖',
    englishName: 'Banshee',
    origin: '愛爾蘭・蘇格蘭傳說',
    scareLevel: 4,
    tagline: '淒厲的哭號，預告死亡將至',
    story:
        '披著一頭長髮、穿著灰白斗篷的女妖。當她在夜裡發出淒厲的哭號，'
        '就代表家族中即將有人過世。不過她並不會害人，'
        '而是為逝者哀悼、傳遞消息的使者。',
    powers: ['預知死亡', '震耳欲聾的尖叫', '化作霧氣消失'],
    weaknesses: ['不會主動傷人，只負責傳遞消息'],
    funFact: 'Banshee 來自愛爾蘭語 bean sídhe，意思是「仙丘的女人」。',
    credit: ImageCredit(
      title: 'Banshee by Philippe Semeria.jpg',
      artist: 'Philippe Semeria',
      license: 'CC BY 3.0',
      url:
          'https://commons.wikimedia.org/wiki/File:Banshee_by_Philippe_Semeria.jpg',
    ),
  ),
];
