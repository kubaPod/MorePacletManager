(* ::Package:: *)

BeginPackage["MPM`"];

  Needs @ "PacletManager`";

  MPMInstall;


Begin["`Private`"];



  $DefaultLogger = Print;


  $ReleaseUrlTemplate = StringTemplate[
    "https://api.github.com/repos/`1`/`2`/releases/<* If[#3=!=\"latest\", \"tags/\", \"\"] *>`3`"
  ];

  $PacletAssetPattern = KeyValuePattern[
    "browser_download_url" -> url_String /; StringEndsQ[url, ".paclet"]
  ] :> url;



MPMInstall // Options = {
        "Method" -> Automatic
      , "Logger" -> Automatic
      (*, "Destination" -> Automatic*)
  };

  MPMInstall::noass = "Couldn't find assets for: ``/``";
  MPMInstall::invmeth = "Unknown method ``";


  MPMInstall::assetsearch = "Searching for assets `1`/`2`/`3`";
  MPMInstall::dload = "Downloading ``...";
  MPMInstall::inst = "Installing ``...";



  MPMInstall[
      args__
    , patt : OptionsPattern[{MPMInstall, PacletInstall}]

  ]:= Module[ { method = OptionValue["Method"] }

    , Switch[ method
        , Automatic | "gh-assets-paclet"
        , GitHubAssetInstall[args, patt]

        , _
        , Message[MPMInstall::invmeth, method]; $Failed
      ]

  ];

    (*TODO: once PacletInstall supports https it will probably go*)
  MPMInstall[
      url_String /; StringMatchQ[url, "http"|"ftp"~~__~~".paclet"]
    , patt : OptionsPattern[{MPMInstall, PacletInstall}]

  ]:= Module[
      { temp
      , piOps = FilterRules[{patt}, Options[PacletInstall]]
      , $logger = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      }

    , temp = FileNameJoin[{$TemporaryDirectory, CreateUUID[] <> ".paclet"}]

         (*TODO: check existence up front*)
    ;  Catch[
           $logger @ StringTemplate[MPMInstall::dload] @ FileNameTake[url]

         ; URLSave[url, temp]

         ; If[
               FileExistsQ @ temp
             , $logger @ StringTemplate[MPMInstall::inst] @ FileNameTake[url]
             ; PacletInstall[ temp, piOps]

             , Throw @ $Failed
           ]
       ]


  ];


  WithPacletRepository[]

  GitHubAssetInstall::usage = "
          GitHubAssetInstall[author, pacletName] installs paclet distributed via GitHub repository release

      ";

  GitHubAssetInstall // Options = Options @ MPMInstall;


  (*TODO: if version is not 'latest' check if it isn't already installed*)
  (*TODO: consider adding 'Force' option that will force overwriting instead of asking user*)
  (*TODO: add conditional progress indicator, based on $Notebooks and $logger wrapper*)

  GitHubAssetInstall[
      author_String
    , paclet_String
    , version_String:"latest"
    , patt : OptionsPattern[{GitHubAssetInstall, PacletInstall}]

  ]:=Module[
      { json
      , downloads
      , pacletInstall
      , $logger = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      }

    , Catch[

          $logger @ StringTemplate[MPMInstall::assetsearch][  author, paclet, version ]

        ; json = Import[
          $ReleaseUrlTemplate[author, paclet, version]
          , "RawJSON"
        ]


        ; downloads = If[
          Not @ MatchQ[
            json
            , KeyValuePattern["assets" -> _List ? (MemberQ[First @ $PacletAssetPattern])]
          ]

          , Message[MPMInstall::noass, paclet, version]
          ; Throw @ $Failed

          , Cases[json["assets"], $PacletAssetPattern ]
        ]

        ; If[
            Length @ downloads > 1
          , MPMInstall[#, patt]& /@ downloads
          , MPMInstall[First @ downloads, patt]
        ]
    ]
  ];




(*      ; target = FileNameJoin[{CreateDirectory[], "paclet.paclet"}]
   ; If[
            $Notebooks
          , PrintTemporary @ Labeled[ProgressIndicator[Appearance -> "Necklace"]
              , "Downloading...", Right]
          , Print["Downloading..."]
        ]
      ; URLSave[download, target]
      , Return[$Failed]
    ]
  ; If[FileExistsQ[target], PacletInstall[target], $Failed]
]*)


End[];

EndPackage[];
