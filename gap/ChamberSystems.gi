## Functions for describing a chamber system in GAP.

BindGlobal( "ChamberSystemFamily",
    NewFamily( "ChamberSystemFamily", IsChamberSystem ) );
BindGlobal( "ChamberSystemType",
    NewType( ChamberSystemFamily, IsChamberSystem and IsChamberSystemRep ) );
BindGlobal( "CosetChamberSystemType",
    NewType( ChamberSystemFamily, IsCosetChamberSystem and IsChamberSystemRep ) );

InstallMethod( ViewObj, [ IsChamberSystem ],
    function(C)
    Print( "<chamber system with ", Size(C!.elements),
           " chambers and types ", C!.types, ">" );
end );

InstallMethod( PrintObj, [ IsChamberSystem ],
    function(C)
    Print( "<chamber system with ", Size(C!.elements),
           " chambers and types ", C!.types, ">" );
end );

#############################################################################
## Helpers

InstallGlobalFunction( IsElementOfChamberSystem,
    function(C, x)
    if not IsChamberSystem(C) then
        Error("C must be a chamber system.");
    fi;
    return x in C!.elements;
end );

InstallGlobalFunction( IsTypeOfChamberSystem,
    function(C, i)
    if not IsChamberSystem(C) then
        Error("C must be a chamber system.");
    fi;
    return i in C!.types;
end );


BindGlobal( "ChamberSystemCheckElement",
    function(C, x)
    if not IsElementOfChamberSystem(C, x) then
        Error("The element must belong to the chamber system.");
    fi;
end );

#############################################################################
## Constructors

InstallMethod( ChamberSystem, [ IsList, IsList, IsList ],
    function(elements, list_of_i_adjacencies, I)
    local i, adj;
    if Size(I) <> Size(list_of_i_adjacencies) then
        Error("The number of types I must match the number of lists of adjacencies.");
    fi;
    for i in [1..Size(I)] do
        if Set(Concatenation(list_of_i_adjacencies[i])) <> Set(elements) then
            Error("Each adjacency partition must cover exactly the elements.");
        fi;
    od;
    adj := HashMap();
    for i in [1..Size(I)] do
        adj[I[i]] := EquivalenceRelationByPartition( Domain(elements),
                                                     list_of_i_adjacencies[i] );
    od;
    return Objectify( ChamberSystemType, rec(
        elements  := elements,
        adjacency := adj,
        types     := I ) );
end );

InstallMethod( CosetChamberSystem, [ IsGroup, IsGroup, IsList, IsList ],
    function(G, B, list_of_Gi, I)
    local elements, Gi, partitions, posGi, treated, coset, cl, adj, i;
    if Size(I) <> Size(list_of_Gi) then
        Error("The number of subgroups Gi must match the number of types I.");
    fi;
    if not IsSubgroup(G, B) then
        Error("B must be a subgroup of G.");
    fi;
    for Gi in list_of_Gi do
        if not IsSubgroup(G, Gi) then
            Error("Each Gi must be a subgroup of G.");
        fi;
        if not IsSubgroup(Gi, B) then
            Error("Each Gi must contain B as a subgroup.");
        fi;
    od;
    elements := AsList( RightCosets(G, B) );
    partitions := [];
    for posGi in [1..Size(list_of_Gi)] do
        partitions[posGi] := [];
        treated := [];
        for coset in elements do
            if coset in treated then
                continue;
            fi;
            cl := Filtered( elements,
                    c -> Representative(c) * Representative(coset)^-1
                         in list_of_Gi[posGi] );
            Add( partitions[posGi], cl );
            Append( treated, cl );
        od;
    od;
    adj := [];
    for i in [1..Size(I)] do
        adj[i] := EquivalenceRelationByPartition( Domain(elements), partitions[i] );
    od;
    return Objectify( CosetChamberSystemType, rec(
        elements  := elements,
        adjacency := adj,
        types     := I,
        group     := G,
        borel     := B,
        subgroups := list_of_Gi ) );
end );

#############################################################################
## Adjacency

InstallMethod( IsAdjacent, [ IsChamberSystem, IsObject, IsObject ],
    function(C, x, y)
    local k;
    ChamberSystemCheckElement(C, x);
    ChamberSystemCheckElement(C, y);
    for k in C!.types do
        if IsAdjacent(C, x, y, k) then
            return true;
        fi;
    od;
    return false;
end );

InstallOtherMethod( IsAdjacent, [ IsChamberSystem, IsObject, IsObject, IsObject ],
    function(C, x, y, i)
    ChamberSystemCheckElement(C, x);
    ChamberSystemCheckElement(C, y);
    if not IsTypeOfChamberSystem(C, i) then
        Error("i must be a type of C.");
    fi;
    return x in EquivalenceClassOfElement( C!.adjacency[i], y );
end );

#############################################################################
## Graph

InstallMethod( GraphOfChamberSystem, [ IsChamberSystem ],
    function(C)
    local Gamma, GraphAdj, GraphEdgeLabel, ele_adj, ele_edge_label,
          pos_ele, k, li, new_li;
    GraphAdj := [];
    GraphEdgeLabel := [];
    for pos_ele in [1..Size(C!.elements)] do
        ele_adj := [];
        ele_edge_label := [];
        for k in C!.types do
            for li in EquivalenceRelationPartition( C!.adjacency[k] ) do
                if C!.elements[pos_ele] in li then
                    new_li := List( li, x -> Position( C!.elements, x ) );
                    Append( ele_adj, Filtered( new_li, x -> x <> pos_ele ) );
                    Append( ele_edge_label,
                            List( [1 .. Size(li)-1], x -> k ) );
                    break;
                fi;
            od;
        od;
        if Size(ele_adj) > Size(Set(ele_adj)) then
            Error("This package does not support graphs with multiple edges between the same pair of vertices.");
        fi;
        Add( GraphAdj, ele_adj );
        Add( GraphEdgeLabel, ele_edge_label );
    od;
    Gamma := Digraph( GraphAdj );
    SetDigraphEdgeLabels( Gamma, GraphEdgeLabel );
    return Gamma;
end );

InstallOtherMethod( GraphOfChamberSystem, [ IsList, IsList, IsList ],
    function(elements, list_of_i_adjacencies, I)
    return GraphOfChamberSystem( ChamberSystem(elements, list_of_i_adjacencies, I) );
end );

InstallOtherMethod( GraphOfChamberSystem, [ IsGroup, IsGroup, IsList, IsList ],
    function(G, B, list_of_Gi, I)
    return GraphOfChamberSystem( CosetChamberSystem(G, B, list_of_Gi, I) );
end );

InstallMethod( DotGraphOfChamberSystem, [ IsDigraph ],
    function(Gamma)
    return DotGraphOfChamberSystem( Gamma, false );
end );

InstallMethod( DotGraphOfChamberSystem, [ IsChamberSystem ],
    function(C)
    return DotGraphOfChamberSystem( GraphOfChamberSystem(C), false );
end );

InstallMethod( DotGraphOfChamberSystem, [ IsDigraph, IsBool ],
    function(Gamma, numbered_vertices)
    local rep, edgecolors, dot;
    edgecolors := List( DigraphEdgeLabels(Gamma), x -> List( x, String ) );
    dot := DotSymmetricEdgeColoredDigraph( Gamma, edgecolors );
    rep := ReplacedString( dot, "color", "label" );
    if not numbered_vertices then
        rep := ReplacedString( rep, "node [shape=circle]",
            "node [label=\"\", shape=circle, width=0.15, fixedsize=true, style=filled, fillcolor=black]" );
    fi;
    return rep;
end );

InstallMethod( DotGraphOfChamberSystem, [ IsChamberSystem, IsBool ],
    function(C, numbered_vertices)
    return DotGraphOfChamberSystem( GraphOfChamberSystem(C), numbered_vertices );
end );

#############################################################################
## Connectedness

InstallMethod( IsConnectedChamberSystem, [ IsChamberSystem ],
    function(C)
    return IsConnectedDigraph( GraphOfChamberSystem(C) );
end );

InstallMethod( IsConnectedChamberSystem, [ IsCosetChamberSystem ],
    function(C)
    return Size( C!.group ) = Size( Subgroup( C!.group,
        Concatenation( List( C!.subgroups, GeneratorsOfGroup ) ) ) );
end );

#############################################################################
## Cells and objects

# Cell generated by a set X of chambers using the types in J.
BindGlobal( "CellOfChamberSystemForSet",
    function(C, X, J)
    local cell, sizeofcell, ele, li, i, T;
    if not IsSubset( Set(C!.types), Set(J) ) then
        Error("J must be a subset of the types of the chamber system.");
    fi;
    T := true;
    cell := X;
    while T do
        sizeofcell := Size(cell);
        for ele in cell do
            for i in J do
                li := EquivalenceClassOfElement( C!.adjacency[i], ele );
                cell := Set(Union(cell, li));
            od;
        od;
        if Size(Set(cell)) = sizeofcell then
            T := false;
        fi;
    od;
    return cell;
end );

InstallMethod( CellOfChamberSystem, [ IsChamberSystem, IsObject, IsList ],
    function(C, x, J)
    ChamberSystemCheckElement(C, x);
    return CellOfChamberSystemForSet( C, [x], J );
end );

InstallMethod( ObjectOfChamberSystem, [ IsChamberSystem, IsObject, IsObject ],
    function(C, x, i)
    IsTypeOfChamberSystem(C, i);
    return CellOfChamberSystem( C, x, Filtered( C!.types, j -> j <> i ) );
end );

#############################################################################
## Residual connectedness

InstallMethod( IsResiduallyConnectedChamberSystem, [ IsChamberSystem ],
    function(C)
    local x, L, J, K, Lcell, Jcell, JKcell, LcapJcell, LcapJ_LcapKcell;
    for x in C!.elements do
        for L in Combinations( C!.types ) do
            Lcell := CellOfChamberSystem( C, x, L );
            for J in Combinations( C!.types ) do
                Jcell := CellOfChamberSystem( C, x, J );
                for K in Combinations( C!.types ) do
                    JKcell := CellOfChamberSystemForSet( C, Jcell, K );
                    LcapJcell := CellOfChamberSystem( C, x, Intersection(L, J) );
                    LcapJ_LcapKcell := CellOfChamberSystemForSet( C, LcapJcell,
                                                    Intersection(L, K) );
                    if Size( Intersection(Lcell, JKcell) )
                       <> Size( LcapJ_LcapKcell ) then
                        return false;
                    fi;
                od;
            od;
        od;
    od;
    return true;
end );

InstallMethod( IsResiduallyConnectedChamberSystem, [ IsCosetChamberSystem ],
    function(C)
    local J, K, L, G_J, G_K, G_L;
    for J in Combinations( [1..Size(C!.types)] ) do
        G_J := Subgroup( C!.group, Concatenation(List(C!.subgroups{J} , x -> GeneratorsOfGroup(x) )));
        for K in Combinations( [1..Size(C!.types)] ) do
            G_K := Subgroup( C!.group, Concatenation(List(C!.subgroups{K} , x -> GeneratorsOfGroup(x) )));
            for L in Combinations( [1..Size(C!.types)] ) do
                G_L := Subgroup( C!.group, Concatenation(List(C!.subgroups{L} , x -> GeneratorsOfGroup(x) )));
                if Size( RightCosetsNC( G_J, Intersection(G_K, G_L) ) )
                   <> Size( Intersection( RightCosetsNC(G_J, G_K),
                                          RightCosetsNC(G_J, G_L) ) ) then
                    return false;
                fi;
            od;
        od;
    od;
    return true;
end );

#############################################################################
## Firm / thin / thick

InstallMethod( IsFirmChamberSystem, [ IsChamberSystem ],
    function(C)
    local k, li;
    for k in C!.types do
        for li in EquivalenceRelationPartition( C!.adjacency[k] ) do
            if Size(li) < 2 then
                return false;
            fi;
        od;
    od;
    return true;
end );

InstallMethod( IsFirmChamberSystem, [ IsCosetChamberSystem ],
    function(C)
    return ForAll( C!.subgroups, H -> Index(H, C!.borel) >= 2 );
end );

InstallMethod( IsThinChamberSystem, [ IsChamberSystem ],
    function(C)
    local k, li;
    for k in C!.types do
        for li in EquivalenceRelationPartition( C!.adjacency[k] ) do
            if Size(li) <> 2 then
                return false;
            fi;
        od;
    od;
    return true;
end );

InstallMethod( IsThinChamberSystem, [ IsCosetChamberSystem ],
    function(C)
    return ForAll( C!.subgroups, H -> Index(H, C!.borel) = 2 );
end );

InstallMethod( IsThickChamberSystem, [ IsChamberSystem ],
    function(C)
    local k, li;
    for k in C!.types do
        for li in EquivalenceRelationPartition( C!.adjacency[k] ) do
            if Size(li) < 3 then
                return false;
            fi;
        od;
    od;
    return true;
end );

InstallMethod( IsThickChamberSystem, [ IsCosetChamberSystem ],
    function(C)
    return ForAll( C!.subgroups, H -> Index(H, C!.borel) >= 3 );
end );

#############################################################################
## Incidence structure

InstallMethod( IncidenceStructureOfChamberSystem, [ IsChamberSystem ],
    function(C)
    local Objects, i, covered, x, iobj, inc_func, type_func;
    Objects := [];
    for i in C!.types do
        covered := [];
        for x in C!.elements do
            if not x in covered then
                iobj := ObjectOfChamberSystem( C, x, i );
                Add( Objects, [ i, iobj ] );
                covered := Union( covered, iobj );
            fi;
        od;
    od;
    inc_func := function( i_ele, j_ele )
        return Size( Intersection( i_ele[2], j_ele[2] ) ) > 0;
    end;
    type_func := function( i_ele ) return i_ele[1]; end;
    return IncidenceStructure( Objects, inc_func, type_func, C!.types );
end );


