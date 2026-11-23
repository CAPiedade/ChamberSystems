########################################################################
##
##  ChamberSystem package
##
##  Copyright 2026
##    A GAP Package for building chamber systems
##
## Licensed under the GPL 2 or later.
##
########################################################################

#! @Chapter Introduction
#!
#! ChamberSystems is a package which does some
#! interesting and cool things
#!
#! @Chapter Functionality
#!
#!
#! @Section Example Methods
#!
#! This section will describe the example
#! methods of ChamberSystems

#! @Description
#!   Insert documentation for your function here


DeclareInfoClass( "InfoChamberSystem" );
SetInfoLevel( InfoChamberSystem, 1 );

DeclareCategory( "IsChamberSystem", IsObject );
DeclareCategory( "IsCosetChamberSystem", IsChamberSystem );

DeclareRepresentation( "IsChamberSystemRep",
    IsComponentObjectRep and IsAttributeStoringRep,
    [ "elements", "adjacency", "types" ] );

DeclareGlobalFunction( "IsElementOfChamberSystem" );
DeclareGlobalFunction( "IsTypeOfChamberSystem" );

DeclareOperation( "ChamberSystem", [ IsList, IsList, IsList ] );
DeclareOperation( "CosetChamberSystem", [ IsGroup, IsGroup, IsList, IsList ] );

DeclareOperation( "IsAdjacent", [ IsChamberSystem, IsObject, IsObject ] );
DeclareOperation( "IsAdjacent", [ IsChamberSystem, IsObject, IsObject, IsObject ] );

DeclareAttribute( "GraphOfChamberSystem", IsChamberSystem );
DeclareOperation( "GraphOfChamberSystem", [ IsList, IsList, IsList ] );
DeclareOperation( "GraphOfChamberSystem", [ IsGroup, IsGroup, IsList, IsList ] );

DeclareOperation( "DotGraphOfChamberSystem", [ IsObject ] );
DeclareOperation( "DotGraphOfChamberSystem", [ IsObject, IsBool ] );

DeclareProperty( "IsConnectedChamberSystem", IsChamberSystem );
DeclareProperty( "IsResiduallyConnectedChamberSystem", IsChamberSystem );
DeclareProperty( "IsFirmChamberSystem", IsChamberSystem );
DeclareProperty( "IsThinChamberSystem", IsChamberSystem );
DeclareProperty( "IsThickChamberSystem", IsChamberSystem );

DeclareOperation( "CellOfChamberSystem", [ IsChamberSystem, IsObject, IsList ] );
DeclareOperation( "ObjectOfChamberSystem", [ IsChamberSystem, IsObject, IsObject ] );
DeclareAttribute( "IncidenceStructureOfChamberSystem", IsChamberSystem );

