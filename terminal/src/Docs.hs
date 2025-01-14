{-# LANGUAGE OverloadedStrings #-}

module Docs
  ( Flags (..),
    Output (..),
    ReportType (..),
    run,
    reportType,
    output,
    docsFile,
  )
where

import BackgroundWriter qualified as BW
import Build qualified
import Data.ByteString.Builder qualified as B
import Data.NonEmptyList qualified as NE
import Directories qualified as Dirs
import Gren.Details qualified as Details
import Gren.Docs qualified as Docs
import Gren.ModuleName qualified as ModuleName
import Json.Encode qualified as Json
import Reporting qualified
import Reporting.Exit qualified as Exit
import Reporting.Task qualified as Task
import System.FilePath qualified as FP
import System.IO qualified as IO
import Terminal (Parser (..))

-- FLAGS

data Flags = Flags
  { _output :: Maybe Output,
    _report :: Maybe ReportType
  }

data Output
  = JSON FilePath
  | DevNull
  | DevStdOut

data ReportType
  = Json

-- RUN

type Task a = Task.Task Exit.Make a

run :: () -> Flags -> IO ()
run () flags@(Flags _ report) =
  do
    style <- getStyle report
    maybeRoot <- Dirs.findRoot
    Reporting.attemptWithStyle style Exit.makeToReport $
      case maybeRoot of
        Just root -> runHelp root style flags
        Nothing -> return $ Left $ Exit.MakeNoOutline

runHelp :: FilePath -> Reporting.Style -> Flags -> IO (Either Exit.Make ())
runHelp root style (Flags maybeOutput _) =
  BW.withScope $ \scope ->
    Dirs.withRootLock root $
      Task.run $
        do
          details <- Task.eio Exit.MakeBadDetails (Details.load style scope root)
          exposed <- getExposed details
          case maybeOutput of
            Just DevNull ->
              do
                buildExposed style root details Build.IgnoreDocs exposed
                return ()
            Just DevStdOut ->
              do
                docs <- buildExposed style root details Build.KeepDocs exposed
                let builder = Json.encodeUgly $ Docs.encode docs
                Task.io $ B.hPutBuilder IO.stdout builder
            Nothing ->
              buildExposed style root details (Build.WriteDocs "docs.json") exposed
            Just (JSON target) ->
              buildExposed style root details (Build.WriteDocs target) exposed

-- GET INFORMATION

getStyle :: Maybe ReportType -> IO Reporting.Style
getStyle report =
  case report of
    Nothing -> Reporting.terminal
    Just Json -> return Reporting.json

getExposed :: Details.Details -> Task (NE.List ModuleName.Raw)
getExposed (Details.Details _ validOutline _ _ _ _) =
  case validOutline of
    Details.ValidApp _ _ ->
      Task.throw Exit.MakeAppNeedsFileNames
    Details.ValidPkg _ _ exposed ->
      case exposed of
        [] -> Task.throw Exit.MakePkgNeedsExposing
        m : ms -> return (NE.List m ms)

-- BUILD PROJECTS

buildExposed :: Reporting.Style -> FilePath -> Details.Details -> Build.DocsGoal a -> NE.List ModuleName.Raw -> Task a
buildExposed style root details docsGoal exposed =
  Task.eio Exit.MakeCannotBuild $
    Build.fromExposed style root details docsGoal exposed

-- PARSERS

reportType :: Parser ReportType
reportType =
  Parser
    { _singular = "report type",
      _plural = "report types",
      _parser = \string -> if string == "json" then Just Json else Nothing,
      _suggest = \_ -> return ["json"],
      _examples = \_ -> return ["json"]
    }

output :: Parser Output
output =
  Parser
    { _singular = "output file",
      _plural = "output files",
      _parser = parseOutput,
      _suggest = \_ -> return [],
      _examples = \_ -> return ["gren.js", "index.html", "/dev/null", "/dev/stdout"]
    }

parseOutput :: String -> Maybe Output
parseOutput name
  | name == "/dev/stdout" = Just DevStdOut
  | isDevNull name = Just DevNull
  | hasExt ".json" name = Just (JSON name)
  | otherwise = Nothing

docsFile :: Parser FilePath
docsFile =
  Parser
    { _singular = "json file",
      _plural = "json files",
      _parser = \name -> if hasExt ".json" name then Just name else Nothing,
      _suggest = \_ -> return [],
      _examples = \_ -> return ["docs.json", "documentation.json"]
    }

hasExt :: String -> String -> Bool
hasExt ext path =
  FP.takeExtension path == ext && length path > length ext

isDevNull :: String -> Bool
isDevNull name =
  name == "/dev/null" || name == "NUL" || name == "$null"
