local colors = import '../Constants/Colors.libsonnet';
local fonts = import '../Constants/Fonts.libsonnet';
local settings = import '../Settings.libsonnet';

{
  local root = self,

  # =====================================
  # 1. 统一配置区
  # =====================================
  local Actions = {
    // 默认态手势映射... (保持原样)
    normalSwipeUp: {
      h: '0', s: '1', z: '2', b: '3', x: '-', m: '=',
      l: '~', d: '4', y: '5', w: '6', j: ';', n: "'",
      c: '/', q: '7', g: '8', f: '9', t: '[',
    },
    normalSwipeDown: {
      h: '`', s: '！', z: '@', b: '#', x: '_', m: '+',
      l: '\\', d: '$', y: '%', w: '^', j: ':', n: '"',
      c: '《', q: '&', g: '*', f: '(', t: '{',
    },
    longPress: {
      l: [{ action: { shortcut: '#左手模式' }, systemImageName: 'keyboard.onehanded.left' }],
      n: [{ action: { shortcut: '#右手模式' }, systemImageName: 'keyboard.onehanded.right' }],
      c: [{ action: { shortcut: '#undo' }, text: '撤消' }], 
      d: [{ action: { shortcut: '#selectText' }, text: '全选' }, { action: { shortcut: '#cut' }, text: '剪切' }],
      y: [{ action: { shortcut: '#copy' }, text: '复制' }, { action: { shortcut: '#paste' }, text: '粘贴' }],
    },
    // 输入态 (Preedit) 配置块
    preedit: {
      swipeUp: {
        h: { text: 'a ia ua' }, s: { text: 'en in' }, z: { text: 'ang iao' },
        b: { text: 'ao iong' }, x: { text: 'uan uai' }, m: { text: 'ie uo' },
        l: { text: 'ai ue üe' }, d: { text: 'u' }, y: { text: 'eng ing' },
        w: { text: 'e' }, j: { text: 'i' }, n: { text: 'an' },
        c: { text: 'ui iang' }, q: { text: 'ian uang' }, g: { text: 'ei un' },
        f: { text: 'ou iu' }, t: { text: 'ong er' },
      },
      swipeDown: {},
    },
  },

  # =====================================
  # 2. 增强型按键函数 (加入开关逻辑)
  # =====================================
  local mk17Button(char, displayLabel) = {
    local parseAction(val) = 
        if std.isString(val) then { action: { character: val } } else val,

    name: char + 'Button',
    params: {
      text: displayLabel,
      action: { character: char },

      // 默认手势
      [if std.objectHas(Actions.normalSwipeUp, char) then 'swipeUp']: parseAction(Actions.normalSwipeUp[char]),
      [if std.objectHas(Actions.normalSwipeDown, char) then 'swipeDown']: parseAction(Actions.normalSwipeDown[char]),
      [if std.objectHas(Actions.longPress, char) then 'longPress']: Actions.longPress[char],

      // --- 关键修改：根据 settings 开关判断是否生成 preedit 逻辑 ---
      [if settings.ShowKeyMap == 'true' then 'whenPreeditChanged']: {
        [if std.objectHas(Actions.preedit.swipeUp, char) then 'swipeUp']: Actions.preedit.swipeUp[char],
        [if std.objectHas(Actions.preedit.swipeDown, char) then 'swipeDown']: Actions.preedit.swipeDown[char],
      },
    },
  },

  # =====================================
  # 3. 实例化按键
  # =====================================
  hButton: mk17Button('h', 'HP'),
  sButton: mk17Button('s', 'Sh'),
  zButton: mk17Button('z', 'Zh'),
  bButton: mk17Button('b', 'B'),
  xButton: mk17Button('x', 'oXü'),
  mButton: mk17Button('m', 'MS'),
  lButton: mk17Button('l', 'L'),
  dButton: mk17Button('d', 'D'),
  yButton: mk17Button('y', 'Y'),
  wButton: mk17Button('w', 'WZ'),
  jButton: mk17Button('j', 'JK'),
  nButton: mk17Button('n', 'NR'),
  cButton: mk17Button('c', 'Ch'),
  qButton: mk17Button('q', 'Q~'),
  gButton: mk17Button('g', 'G'),
  fButton: mk17Button('f', 'CF'),
  tButton: mk17Button('t', 'T'),

  letterButtons: [
    self.hButton, self.sButton, self.zButton, self.bButton, self.xButton, self.mButton,
    self.lButton, self.dButton, self.yButton, self.wButton, self.jButton, self.nButton,
    self.cButton, self.qButton, self.gButton, self.fButton, self.tButton,
  ],
}
