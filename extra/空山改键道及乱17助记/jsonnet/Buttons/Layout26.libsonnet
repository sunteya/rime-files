local colors = import '../Constants/Colors.libsonnet';
local fonts = import '../Constants/Fonts.libsonnet';
local settings = import '../Settings.libsonnet';

{
  local root = self,

  # =====================================
  # 1. 统一配置区
  # =====================================
  local Actions = {
    // 1. 上滑符号定义 (注意大小写拼写统一)
    normalSwipeUp: {
      q: '1', w: '2', e: '3', r: '4', t: '5', y: '6', u: '7', i: '8', o: '9', p: '0',
      a: '!', s: '^', d: '/', f: ';', g: '(', h: '-', j: '#', k: '{', l: '"',
      z: '@', x: '*', c: '`', v: '=', b: '[', n: '&', m: '?',
    },
    // 2. 下滑功能定义
    normalSwipeDown: {
      q: { action: 'tab', systemImageName: 'arrow.right.to.line' },
      i: { action: { character: '|' } },
      o: { action: { character: '<' } },
      p: { action: { character: '>' } },
      a: { action: { shortcut: '#selectText' }, text: '全', systemImageName: 'selection.pin.in.out' },
      s: { action: { character: '%' } },
      d: { action: { character: '\\' } },
      f: { action: { character: ':' } },
      g: { action: { character: ')' } },
      h: { action: { character: '_' } },
      j: { action: { character: '+' } },
      k: { action: { character: '}' } },
      l: { action: { character: "'" } },
      z: { action: { shortcut: '#undo' }, text: '撤', systemImageName: 'arrow.uturn.left' },
      x: { action: { shortcut: '#cut' }, text: '剪', systemImageName: 'scissors' },
      c: { action: { shortcut: '#copy' }, text: '复', systemImageName: 'doc.on.doc' },
      v: { action: { shortcut: '#paste' }, text: '贴', systemImageName: 'doc.on.clipboard' },
      b: { action: { character: ']' } },
      n: { action: { character: '~' } },
      m: { action: { character: '$' } },
    },
    // 3. 长按功能
    longPress: {
      a: [
        { action: { character: 'A' }, selected: true },
        { action: { shortcut: '#左手模式' }, systemImageName: 'keyboard.onehanded.left' },
      ],
      l: [
        { action: { shortcut: '#右手模式' }, systemImageName: 'keyboard.onehanded.right' },
        { action: { character: 'L' }, selected: true },
      ],
      default: function(char) [{ action: { character: std.asciiUpper(char) } }],
    },
    // 4. 输入态 (Preedit) 
    preedit: {
      swipeUp: {
        q: { text: 'iu ua' }, w: { text: 'ei un' }, e: { text: 'sh e' }, r: { text: 'eng' }, t: { text: 'uan' },
        y: { text: 'ong' }, u: { text: '丿月' }, i: { text: '丨亻' }, o: { text: '丶口' }, p: { text: 'ang' },
        a: { text: '乛氵' }, s: { text: 'a ia' }, d: { text: 'ie ou' }, f: { text: 'zh an' }, g: { text: 'ing' },
        h: { text: 'ai üe' }, j: { text: 'u er' }, k: { text: 'i' }, l: { text: 'o uo' }, z: { text: 'ao' },
        x: { text: 'uang' }, c: { text: 'iao' }, v: { text: '一木' }, b: { text: 'in ui' }, n: { text: 'en' },
        m: { text: 'uang' },
      },
      swipeDown: {
        q: { text: 'zh' }, w: { text: 'ch' },y: { text: 'iong' }, u: { text: '十' }, i: { text: '扌艹 钅' }, o: { text: '日' },
        a: { text: '贝' },   g: { text: 'uai' }, j: { text: 'ch'}, l: { text: 'ü' },
				x: { text: 'iang' }, v: { text: '土' }, m: { text: 'ian' },
      },
    },
  },

  # =====================================
  # 2. 增强型按键函数 (修正函数名和逻辑)
  # =====================================
local mkButton(char) = {
    local parseAction(val) = 
        if std.isString(val) then { action: { character: val } } else val,

    name: char + 'Button',
    params: {
      action: { character: char },

      // --- 核心修复：添加大写状态配置 ---
      // 当按下 Shift (Uppercased) 或 开启大写锁定 (CapsLocked) 时
      // 显式指定发送大写字母的 action[span_0](start_span)[span_0](end_span)
      uppercased: {
        action: { character: std.asciiUpper(char) },
      },
      capsLocked: {
        action: { character: std.asciiUpper(char) },
      },
      // ------------------------------

      // 自动生成大写字母显示，如果 Actions.preedit 有则显示刻印内容[span_1](start_span)[span_1](end_span)
      [if settings.ShowKeyMap == 'true' then 'swipeUpText']: if std.objectHas(Actions.preedit.swipeUp, char) then Actions.preedit.swipeUp[char].text else '',
      [if settings.ShowKeyMap == 'true' then 'swipeDownText']: if std.objectHas(Actions.preedit.swipeDown, char) then Actions.preedit.swipeDown[char].text else '',

      // 默认手势[span_2](start_span)[span_2](end_span)
      [if std.objectHas(Actions.normalSwipeUp, char) then 'swipeUp']: parseAction(Actions.normalSwipeUp[char]),
      [if std.objectHas(Actions.normalSwipeDown, char) then 'swipeDown']: parseAction(Actions.normalSwipeDown[char]),
      
      // 长按：优先用自定义，否则用默认函数[span_3](start_span)[span_3](end_span)
      longPress: if std.objectHas(Actions.longPress, char) then Actions.longPress[char] else Actions.longPress.default(char),

      // 输入态动态手势[span_4](start_span)[span_4](end_span)
      [if settings.ShowKeyMap == 'true' then 'whenPreeditChanged']: {
        [if std.objectHas(Actions.preedit.swipeUp, char) then 'swipeUp']: Actions.preedit.swipeUp[char],
        [if std.objectHas(Actions.preedit.swipeDown, char) then 'swipeDown']: Actions.preedit.swipeDown[char],
      },
    },
  },
  # =====================================
  # 3. 实例化按键
  # =====================================
  qButton: mkButton('q'), wButton: mkButton('w'), eButton: mkButton('e'), rButton: mkButton('r'), tButton: mkButton('t'),
  yButton: mkButton('y'), uButton: mkButton('u'), iButton: mkButton('i'), oButton: mkButton('o'), pButton: mkButton('p'),
  aButton: mkButton('a'), sButton: mkButton('s'), dButton: mkButton('d'), fButton: mkButton('f'), gButton: mkButton('g'),
  hButton: mkButton('h'), jButton: mkButton('j'), kButton: mkButton('k'), lButton: mkButton('l'),
  zButton: mkButton('z'), xButton: mkButton('x'), cButton: mkButton('c'), vButton: mkButton('v'), bButton: mkButton('b'),
  nButton: mkButton('n'), mButton: mkButton('m'),

  letterButtons: [
    self.qButton, self.wButton, self.eButton, self.rButton, self.tButton,
    self.yButton, self.uButton, self.iButton, self.oButton, self.pButton,
    self.aButton, self.sButton, self.dButton, self.fButton, self.gButton,
    self.hButton, self.jButton, self.kButton, self.lButton,
    self.zButton, self.xButton, self.cButton, self.vButton, self.bButton,
    self.nButton, self.mButton,
  ],
}
