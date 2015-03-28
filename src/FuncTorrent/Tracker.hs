module FuncTorrent.Tracker
    (connect,
     infoHash,
     prepareRequest,
     urlEncodeHash
    ) where

import Prelude hiding (lookup)
import Crypto.Hash.SHA1 (hash)
import Data.ByteString.Char8 (ByteString,  unpack)
import Data.Char (chr)
import Data.List (intercalate)
import Data.Maybe (fromJust)
import Data.Map ((!))
import Network.HTTP (simpleHTTP, defaultGETRequest_, getResponseBody)
import Network.HTTP.Base (urlEncode)
import Network.URI (parseURI)
import qualified Data.ByteString.Base16 as B16 (encode)

import FuncTorrent.Bencode (InfoDict, encode)
import FuncTorrent.Utils (splitN)

type Url = String

-- | urlEncodeHash
--
-- >>> urlEncodeHash $ pack "123456789abcdef123456789abcdef123456789a"
-- "%124Vx%9a%bc%de%f1%23Eg%89%ab%cd%ef%124Vx%9a"
urlEncodeHash :: ByteString -> String
urlEncodeHash bs = concatMap (encode' . unpack) (splitN 2 bs)
  where encode' b@[c1, c2] = let c =  chr (read ("0x" ++ b))
                            in escape c c1 c2
        encode' _ = ""
        escape i c1 c2 | i `elem` nonSpecialChars = [i]
                       | otherwise = "%" ++ [c1] ++ [c2]

        nonSpecialChars = ['A'..'Z'] ++ ['a'..'z'] ++ ['0'..'9'] ++ "-_.~"

infoHash :: InfoDict -> ByteString
infoHash m = hash . encode $ (m ! "info")

prepareRequest :: InfoDict -> String -> Integer -> String
prepareRequest d peer_id len =
  let p = [("info_hash", urlEncodeHash ((B16.encode . infoHash) d)),
           ("peer_id", urlEncode peer_id),
           ("port", "6881"),
           ("uploaded", "0"),
           ("downloaded", "0"),
           ("left", show len),
           ("compact", "1"),
           ("event", "started")]
  in intercalate "&" [f ++ "=" ++ s | (f,s) <- p]

connect :: Url -> String -> IO ByteString
connect baseurl qstr = simpleHTTP (defaultGETRequest_ url) >>= getResponseBody
    where url = fromJust . parseURI $ (baseurl ++ "?" ++ qstr)
