{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}

module FuncTorrent.PeerThread where

-- Description
-- PeerThread controls peer-peer communication
-- For each peer a separate instance of PeerThread is used

import Control.Concurrent
import System.Timeout
import Data.IORef

-- Should we use this instead of Network?
import Network.Socket

import FuncTorrent.Peer
import FuncTorrent.PeerThreadData

#ifdef PEER_THREAD_MOCKED
import PeerThreadMock (peerThreadMain)
#else
import FuncTorrent.PeerThreadMain (peerThreadMain)
#endif


-- PeerThread is responsible for 
-- 1. Hand-shake with peer
-- 2. Keeping track of peer state and managing our state with peer.
--    This includes the choke/interested status and have properties.
--    
-- 3. Initiate request to get data.
--    The main thread will allocate a bunch of blocks for fetching from the peer.
--    
-- 4. Respond to data-request.
--    Algo to manage data-request
--
-- 5. Do data checking and disk IO. (Disk IO might be handled in a separate thread?)
-- 
-- 6. If needed, keep the connection alive.
--

--
-- The communication between control thread and peer thread is through
-- status and action.

defaultPeerState = undefined

initPeerThread :: Peer -> IO (PeerThread, ThreadId)
initPeerThread p = do
  s <- newEmptyMVar
  a <- newEmptyMVar
  i <- newIORef defaultPeerState
  let pt = PeerThread p i s a
  tid <- forkIO $ peerThreadMain pt
  putMVar (action pt) InitPeerConnection
  return (pt, tid)


-- Gracefully exit a thread
stopPeerThread :: PeerThread -> IO ()
stopPeerThread _ = undefined

