import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util


ottFile = "Gen/ott-rules.tex"
doc = "Thesis"
ottFlags = "-tex_wrap false -tex_show_meta false"
lhsFlags = "--poly -o"


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
      genLhsFiles <-
        (\mngSource ->
           ["Gen" </> (dropDirectory1 c -<.> "lhstex") | c <- mngSource]) <$>
        getDirectoryFiles "" ["Sources//*.lhsmngtex"]
      need $ [ottFile] ++ genFiles ++ texSource ++ codeSource ++ genLhsFiles
      cmd "latexmk" [doc -<.> "tex"]

    "Gen//*.lhstex" %> \out -> do
      ottSource <- getDirectoryFiles "" ["spec/*.ott"]
      let dep = "Sources" </> dropDirectory1 out -<.> ".lhsmngtex"
          tmp = out -<.> ".tmp"
      need $ dep : ottSource
      cmd_ "ott" ottSource ottFlags "-tex_filter" [dep] [tmp]
      cmd "lhs2Tex" lhsFlags [out] [tmp]

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
