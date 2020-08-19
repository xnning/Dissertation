import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util


ottFile = "Gen/ott-rules.tex"
doc = "Thesis"
ottFlags = "-tex_wrap false -tex_show_meta false"


main :: IO ()
main =
  shakeArgs shakeOptions {shakeFiles = "_build"} $ do
    want [doc <.> "pdf"]

    "*.pdf" %> \_ -> do
      texSource <- getDirectoryFiles "" ["/*.tex", "Sources//*.tex"]
      codeSource <- getDirectoryFiles "" ["examples/*.sl"]
      genFiles <-
        (\mngSource ->
           ["Gen" </> (dropDirectory1 c -<.> "tex") | c <- mngSource]) <$>
        getDirectoryFiles "" ["Sources//*.mngtex"]
      need $ [ottFile] ++ genFiles ++ texSource ++ codeSource
      cmd "latexmk" [doc -<.> "tex"]

    "Gen//*.tex" %> \out -> do
      ottSource <- getDirectoryFiles "" ["spec/*.ott"]
      let dep = "Sources" </> dropDirectory1 out -<.> ".mngtex"
      need $ dep : ottSource
      cmd "ott" ottSource ottFlags "-tex_filter" [dep] [out]

    ottFile %> \out -> do
      ottSource <- getDirectoryFiles "" ["spec/*.ott"]
      need ottSource
      cmd "ott" ottSource ottFlags "-o" [out]

    phony "clean" $ do
      putNormal "Cleaning files in _build"
      removeFilesAfter "_build" ["//*"]
      cmd "latexmk -c"
