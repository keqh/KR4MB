
import Text.KR4MB
import Control.Monad (forM_)

dest_path = "/Users/keqh/Library/Application Support/KeyRemap4MacBook/private.xml"

main = do
    reload dest_path rule

rule :: Rule
rule = root $ do
  item "personal settings" $ do
    keyOverlaidModifier CONTROL_L CONTROL_L [JIS_EISUU, ESCAPE]

    ':' `swapKey` ':'
    ';' `swapKey` '_'

    appendix "Google IME"
    ctrl 'j' `keyToKey` ctrl (shift 'j')

  group "standard settings" $ do
    item "JIS to US" $ do
        setJSLayout

    item "basic settings" $ do
      COMMAND_L `keyToKey` OPTION_L
      JIS_KANA `keyToKey` RETURN
      keyOverlaidModifier JIS_EISUU COMMAND_L [JIS_EISUU]
      SPACE `keyOverlaidModifierWithRepeat` SHIFT_L

      F7 `keyToConsumer` MUSIC_PREV
      F8 `keyToConsumer` MUSIC_PLAY
      F9 `keyToConsumer` MUSIC_NEXT

      F10 `keyToConsumer` VOLUME_MUTE
      F11 `keyToConsumer` VOLUME_DOWN
      F12 `keyToConsumer` VOLUME_UP

  group "use extra1" $ do
    item "for symbol keycode" $ do
      appendix "Modと併用時は普通にshiftとして動作する"
      forM_ [cmd, opt, ctrl] $ \modkey -> do
          modkey SHIFT_L `keyToKey` modkey SHIFT_L
      SHIFT_L `keyToKey` VK_MODIFIER_EXTRA1

      --  appendix "extra1と同時押しでa-lを最上段に変換"
      --  forM_ (zip "asdfghjkl;" "!@#$%^&*()") $ \(c,sym) -> do
      --    extra1 c `keyToKey` sym

      -- EXTRA1に依存してるので整理すること
    item "for tmux" $ do
      let focusiTerm = opt $ ctrl $ shift 'z'
      let tmuxPrefix = ctrl 't'
      forM_ "[uiopnc" $ \key -> do
        extra1 key `keyToKey'` [toKey JIS_EISUU, focusiTerm, tmuxPrefix, toKey key]

    item "chrome" $ do
          -- alfredでF3でchromeにfocusが行くよう設定
          let focusChrome = toKey F3
          forM_ "jk" $ \key -> do
            extra1 key `keyToKey'` [toKey JIS_EISUU, focusChrome, toKey key]

  item "for coding" $ do
    extra1 '.' `keyToKey'` " -> "
    extra1 'w' `keyToKey'` "\n  where\n"

