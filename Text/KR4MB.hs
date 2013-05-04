{-# LANGUAGE QuasiQuotes, ExtendedDefaultRules #-}
{-# LANGUAGE TypeSynonymInstances, FlexibleInstances #-}

module Text.KR4MB where

import Control.Monad.RWS
import Data.Char (toLower, toUpper)
import Data.List (intercalate)
import qualified System.Process.QQ as P

type Rule = RWS () String Int ()
indentLevel = 4
defaultIndentLevel = 0

run rule = let (state, xml) = execRWS rule () defaultIndentLevel in xml

output :: Rule -> IO ()
output = putStrLn . run

-- reload settings
-- =========================

cli_path = "/Applications/KeyRemap4MacBook.app/Contents/Applications/KeyRemap4MacBook_cli.app/Contents/MacOS/KeyRemap4MacBook_cli"

reload :: FilePath -> Rule -> IO ()
reload private_xml_path rule = do
    writeFile private_xml_path $ run rule
    [P.cmd|#{cli_path} reloadxml|]
    return ()

-- utility
-- =========================

tell' tag s = do
    tellIndent
    tell $ "<" ++ tag ++ ">" ++ s ++ "</" ++ tag ++ ">\n"

tellIndent = do
    indent <- get
    tell $ replicate indent ' '

wrap :: String -> Rule -> Rule
wrap tagname rule = do
    tellIndent
    tell $ "<" ++ tagname ++ ">\n"
    modify $ (+ indentLevel)
    rule
    modify $ (subtract indentLevel)
    tellIndent
    tell $ "</" ++ tagname ++ ">\n"

toIdentifier :: String -> String
toIdentifier s = "private." ++ [toLower c | c <- s, c /= ' ']

-- main functions
-- =========================

root :: Rule -> Rule
root rule = do
    tell $ "<?xml version=\"1.0\"?>\n"
    wrap "root" rule

group :: String -> Rule -> Rule
group name config = wrap "item" $ do
    tell' "name" name
    config

item :: String -> Rule -> Rule
item name config = wrap "item" $ do
    tell' "name" name
    tell' "identifier" $ toIdentifier name
    config

appendix :: String -> Rule
appendix message = tell' "appendix" message

autogen :: String -> Rule
autogen contents = tell' "autogen" contents

-- keyremap
-- =========================

keyOverlaidModifier :: (KeyBehavior a) => a -> a -> [a] -> Rule
keyOverlaidModifier base normal single = do
    let base' = show $ toKey base
    let normal' = show $ toKey normal
    let single' = intercalate ", " $ map (show . toKey) single
    autogen $ "__KeyOverlaidModifier__ " ++ (base' ++ ", " ++ normal' ++ ", " ++ single')

keyOverlaidModifierWithRepeat :: (KeyBehavior a) => a -> a -> Rule
keyOverlaidModifierWithRepeat base normal = do
    let base' = show $ toKey base
    let normal' = show $ toKey normal
    autogen $ "__KeyOverlaidModifierWithRepeat__ " ++ (base' ++ ", " ++ normal' ++ ", " ++ base')


keyToKey :: (KeyBehavior a, KeyBehavior b) => a -> b -> Rule
keyToKey old new = do
    let old' = show $ toKey old
    let new' = show $ toKey new
    autogen $ "__KeyToKey__ " ++ (old' ++ ", " ++ new')

keyToKey' :: (KeyBehavior a, KeyBehavior b) => a -> [b] -> Rule
keyToKey' old seqs = do
    let old' = show $ toKey old
    let seqs' = intercalate ", " $ map (show . toKey) seqs
    autogen $ "__KeyToKey__ " ++ (old' ++ ", " ++ seqs')

--keyToConsumer :: a
keyToConsumer old new = do
    let old' = show $ toKey old
    let new' = show $ toKey new
    autogen $ "__KeyToConsumer__ " ++ (old' ++ ", " ++ new')

-- contributes
-- =========================

swapKey :: (KeyBehavior a, KeyBehavior b) => a -> b -> Rule
swapKey k1 k2 = do
    k1 `keyToKey` k2
    k2 `keyToKey` k1

keySequence :: String -> [Key]
keySequence = map toKey

setJSLayout = do
    autogen $ "__SetKeyboardType__ KeyboardType::MACBOOK"
    JIS_YEN `keyToKey` '`'
    JIS_UNDERSCORE `keyToKey` '`'

-- modkeys
-- =========================
shift, control, command, option, extra1 :: (KeyBehavior a) => a -> Key
shift k = hoge M_SHIFT_L (toKey k)
control k = hoge M_CONTROL_L (toKey k)
command k = hoge M_COMMAND_L (toKey k)
option k = hoge M_OPTION_L (toKey k)
extra1 k = hoge M_EXTRA1 (toKey k)

cmd, opt, ctrl :: (KeyBehavior a) => a -> Key
cmd = command
opt = option
ctrl = control

hoge mod (Key code mods) = Key code (mod : mods)

-- data definitions
-- =========================

data Key = Key KeyCode [ModKey]

data KeyCode
    = C Char
    | ConsumerKey ConsumerKey
    | CONTROL_L | SHIFT_L | OPTION_L | COMMAND_L
    | CONTROL_R | SHIFT_R | OPTION_R | COMMAND_R
    | VK_MODIFIER_EXTRA1
    | JIS_EISUU | JIS_KANA | JIS_YEN | JIS_UNDERSCORE | ESCAPE
    | RETURN | SPACE
    | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12
    deriving (Show)

data ConsumerKey
    = MUSIC_PREV | MUSIC_PLAY | MUSIC_NEXT
    | VOLUME_MUTE | VOLUME_DOWN | VOLUME_UP
    deriving (Show)

data ModKey = M_SHIFT_L | M_CONTROL_L | M_COMMAND_L | M_OPTION_L | M_EXTRA1 deriving (Show)

class (Show a) => KeyBehavior a where
    toKey :: a -> Key

instance KeyBehavior Key where
    toKey = id

instance KeyBehavior KeyCode where
    toKey code = Key code []

instance KeyBehavior ConsumerKey where
    toKey ckey = Key (ConsumerKey ckey) []

instance KeyBehavior Char where
    toKey c | Just c' <- lookup c shiftKeyMap = Key (C c') [M_SHIFT_L]
    toKey c = Key (C c) []

-- english key layout
shiftKeyMap = zip "!@#$%^&*()_+~QWERTYUIOP{}ASDFGHJKL:\"|ZXCVBNM<>?~" "1234567890-=`qwertyuiop[]asdfghjkl;'\\zxcvbnm,./`"

-- convert private.xml
-- =========================

instance Show Key where
    show (Key code []) = showKeyCode code
    show (Key code mods) = showKeyCode code ++ ", " ++ intercalate " | " (map showModKey mods)

keyCodePrefix :: String -> String
keyCodePrefix s = "KeyCode::" ++ s

showKeyCode :: KeyCode -> String
showKeyCode (C ';') = keyCodePrefix "SEMICOLON"
showKeyCode (C '-') = keyCodePrefix "MINUS"
showKeyCode (C '[') = keyCodePrefix "BRACKET_LEFT"
showKeyCode (C '.') = keyCodePrefix "DOT"
showKeyCode (C ' ') = keyCodePrefix "SPACE"
showKeyCode (C '`') = keyCodePrefix "BACKQUOTE"
showKeyCode (C '\n') = keyCodePrefix "ENTER"
showKeyCode (C c)
  | c `elem` "1234567890" = keyCodePrefix $ "KEY_" ++ [c]
  | otherwise = keyCodePrefix [toUpper c]
showKeyCode (ConsumerKey ckey) = "ConsumerKeyCode::" ++ show ckey
showKeyCode code = keyCodePrefix $ show code

showModKey :: ModKey -> String
showModKey modkey = "ModifierFlag::" ++ drop 2 (show modkey)

