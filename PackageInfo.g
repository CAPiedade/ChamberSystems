#
# ChamberSystems: Implementation of Chamber systems into GAP-Systems
#
# This file contains package meta data. For additional information on
# the meaning and correct usage of these fields, please consult the
# manual of the "Example" package as well as the comments in its
# PackageInfo.g file.
#
SetPackageInfo( rec(

PackageName := "ChamberSystems",
Subtitle := "Implementation of Chamber systems into GAP-Systems",
Version := "0.1",
Date := "23/11/2026", # dd/mm/yyyy format
License := "GPL-2.0-or-later",

Persons := [
  rec(
    FirstNames := "Claudio",
    LastName := "Piedade",
    WWWHome := "https://capiedade.github.io",
    Email := "claudioalexandrepiedade@gmail.com",
    IsAuthor := true,
    IsMaintainer := true,
    PostalAddress := "1050",
    Place := "Brussels, Belgium",
    Institution := "Universitée' Libre de Bruxelles",
    GitHubUsername := "CAPiedade",
  ),
],

SourceRepository := rec(
    Type := "git",
    URL := "https://github.com/CAPiedade/ChamberSystems",
),
IssueTrackerURL := Concatenation( ~.SourceRepository.URL, "/issues" ),
PackageWWWHome  := "https://CAPiedade.github.io/ChamberSystems/",
PackageInfoURL  := Concatenation( ~.PackageWWWHome, "PackageInfo.g" ),
README_URL      := Concatenation( ~.PackageWWWHome, "README.md" ),
ArchiveURL      := Concatenation( ~.SourceRepository.URL,
                                 "/releases/download/v", ~.Version,
                                 "/", ~.PackageName, "-", ~.Version ),

ArchiveFormats := ".tar.gz",

AbstractHTML   :=  "",

PackageDoc := rec(
  BookName  := "ChamberSystems",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0_mj.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Implementation of Chamber systems into GAP-Systems",
),

Dependencies := rec(
  GAP := ">= 4.13",
  NeededOtherPackages := [ ],
  SuggestedOtherPackages := [ ],
  ExternalConditions := [ ],
),

AvailabilityTest := ReturnTrue,

TestFile := "tst/testall.g",

));
