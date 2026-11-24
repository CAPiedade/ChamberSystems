## Functions for describing a chamber system in GAP.

BindGlobal( "ChamberSystemFamily",
    NewFamily( "ChamberSystemFamily", IsChamberSystem ) );
BindGlobal( "ChamberSystemType",
    NewType( ChamberSystemFamily, IsChamberSystem and IsChamberSystemRep ) );
BindGlobal( "CosetChamberSystemType",
    NewType( ChamberSystemFamily, IsCosetChamberSystem and IsChamberSystemRep ) );

BindGlobal( "ChamberSystemGraphFamily",
    NewFamily( "ChamberSystemGraphFamily", IsChamberSystemGraph ) );
BindGlobal( "ChamberSystemGraphType",
    NewType( ChamberSystemGraphFamily, IsChamberSystemGraph and IsChamberSystemGraphRep ) );

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

InstallMethod( ViewObj, [ IsChamberSystemGraph ],
    function(gamma)
    Print( "<chamber system graph with ", Size(gamma!.elements),
           " vertices and types ", gamma!.types, ">" );
end );

InstallMethod( PrintObj, [ IsChamberSystemGraph ],
    function(gamma)
    Print( "<chamber system graph with ", Size(gamma!.elements),
           " vertices and types ", gamma!.types, ">" );
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
    adj := HashMap();
    for i in [1..Size(I)] do
        adj[I[i]] := EquivalenceRelationByPartition( Domain(elements), partitions[i] );
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
    local gamma, GraphAdj, GraphEdgeLabel, ele_adj, ele_edge_label,
          pos_ele, k, li, new_li, obj;
    GraphAdj := [];
    GraphEdgeLabel := [];
    for pos_ele in [1..Size(C!.elements)] do
        ele_adj := [];
        ele_edge_label := [];
        for k in C!.types do
            for li in EquivalenceRelationPartition( C!.adjacency[k] ) do
                if C!.elements[pos_ele] in li then
                    new_li := List( li, x -> Position( C!.elements, x ));
                    Append( ele_adj, Filtered( new_li, x -> x <> pos_ele ) );
                    Append( ele_edge_label, List( [1 .. Size(li)-1], x -> k ) );
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
    gamma := Digraph( GraphAdj );
    SetDigraphEdgeLabels( gamma, GraphEdgeLabel );
    obj := Objectify( ChamberSystemGraphType, rec(
        graph := gamma,
        elements := C!.elements,
        types := C!.types ) );
    C!.graph := obj;
    return obj;
end );

InstallOtherMethod( GraphOfChamberSystem, [ IsList, IsList, IsList ],
    function(elements, list_of_i_adjacencies, I)
    return GraphOfChamberSystem( ChamberSystem(elements, list_of_i_adjacencies, I) );
end );

InstallOtherMethod( GraphOfChamberSystem, [ IsGroup, IsGroup, IsList, IsList ],
    function(G, B, list_of_Gi, I)
    return GraphOfChamberSystem( CosetChamberSystem(G, B, list_of_Gi, I) );
end );

InstallMethod( DotGraphOfChamberSystem, [ IsChamberSystemGraph ],
    function(gamma)
    return DotGraphOfChamberSystem( gamma, false );
end );

InstallMethod( DotGraphOfChamberSystem, [ IsChamberSystem ],
    function(C)
    return DotGraphOfChamberSystem( GraphOfChamberSystem(C), false );
end );

InstallMethod( DotGraphOfChamberSystem, [ IsChamberSystemGraph, IsBool ],
    function(gamma, numbered_vertices)
    local rep, edgecolors, dot;
    edgecolors := List( DigraphEdgeLabels(gamma!.graph), x -> List( x, String ) );
    dot := DotSymmetricEdgeColoredDigraph( gamma!.graph, edgecolors );
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
    local G, Gs, G_of, Js, L, J, K, G_L, G_J, G_K, G_JL, G_JK, G_JK_GJL, G_K_G_L;
    Js := Combinations( [1..Size(C!.types)] );
    Gs := List( Js, function(S)
        if IsEmpty(S) then
            return C!.borel;
        fi;
        return Subgroup( C!.group,
            Concatenation( List( C!.subgroups{S}, GeneratorsOfGroup ) ) );
    end );
    G_of := S -> Gs[ Position( Js, S ) ];
    for L in Js do
        G_L := G_of(L);
        for J in Js do
            G_J := G_of(J);
            G_JL := G_of( Intersection(J, L) );
            for K in Js do
                G_K := G_of(K);
                G_JK := G_of( Intersection(J, K) );
                G_JK_GJL := Filtered( RightCosets(C!.group, G_JL), rc ->  Size(Intersection(rc, G_JK)) > 0);
                G_K_G_L := Filtered( RightCosets(C!.group, G_L), rc -> Size(Intersection(rc, G_K)) > 0);
                if Size(Intersection(G_J ,Flat(List(G_K_G_L, x -> List(x))))) <> Size(Flat(List(G_JK_GJL, x -> List(x)))) then
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
## Incidence structure <-> Chamber system

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


#InstallMethod( ChamberSystem, [ IsIncidenceStructure ],
#    function(I)
#        #TODO
#    end );


#############################################################################
## Automorphism Group

InstallOtherMethod( AutomorphismGroup, [ IsChamberSystem ],
    function(C)
    local gamma;
    if IsBound( C!.autgroup) then
        return C!.autgroup;
    fi;
    if not IsBound( C!.graph ) then
        GraphOfChamberSystem(C);
    fi;
    gamma := C!.graph;
    C!.autgroup := AutomorphismGroup(gamma);
    return C!.autgroup;
end );

InstallOtherMethod( AutomorphismGroup, [ IsChamberSystemGraph ],
    function(gamma)
    local thegraph;
    if IsBound( gamma!.autgroup) then
        return gamma!.autgroup;
    fi;
    gamma!.autgroup := AutomorphismGroup(gamma!.graph, fail, DigraphEdgeLabels(gamma!.graph));
    return gamma!.autgroup;
end );

InstallMethod( QuotientChamberSystem, [ IsChamberSystem, IsGroup ],
    function(C, G)
    local quotient_elements, I, list_of_i_adjacencies, i_adj_to_ele, i, covered, ele, ele2, t, x, y; 
    if not IsBound( C!.autgroup ) then
        Error("The group G must be a subgroup of the automorphism group of the chamber system. Please compute the automorphism group first.");
    fi;
    if not IsSubgroup( C!.autgroup, G ) then
        Error("The group G must be a subgroup of the automorphism group of the chamber system.");
    fi;
    quotient_elements := List(Set( List( [1 .. Size(C!.elements)], x -> Set(Orbit(G, x)))), x -> C!.elements{x}) ;
    I := C!.types;
    list_of_i_adjacencies := [];
    for i in [1..Size(I)] do
        list_of_i_adjacencies[i] := [];
        covered := [];
        for ele in quotient_elements do
            if not ele in covered then
                i_adj_to_ele := [ele];
                for ele2 in quotient_elements do
                    t := false;
                    if ele <> ele2 then
                        for x in ele do
                            for y in ele2 do
                                if IsAdjacent(C, x, y, I[i]) then
                                    Add( i_adj_to_ele, ele2 );
                                    Add(covered, ele2);
                                    t := true;
                                    break ;
                                fi;
                            od;
                            if t then
                                break;
                            fi;
                        od;
                    fi;
                od; 
                Add(list_of_i_adjacencies[i], i_adj_to_ele);
            fi;
        od;
    od;
    return ChamberSystem(quotient_elements, list_of_i_adjacencies, I);
end );



#############################################################################
## Operation on Coset Chamber Systems

### I NEED TO DEAL WITH TYPES NOT >1 ... PROBLEM IN AUTOMORPHISM GROUP AND NOW HERE ###

InstallMethod( PhiTypeSet, [IsCosetChamberSystem, IsCosetChamberSystem, IsGroupHomomorphism],
    function(C_a, C_b, phi)
    local SizeTypes, aut, gens_g_As_Action, collect_g_gens, SymGroup, g, g_gen, maxP_type, sent_type;
    SizeTypes := Size( C_a!.types);
    gens_g_As_Action := [];
    collect_g_gens := [];
    SymGroup := SymmetricGroup(C_a!.types);
    for aut in GeneratorsOfGroup(Image(phi, C_b!.group)) do
        if Image(aut, C_a!.borel) <> C_a!.borel then
            Error("phi must be a homomorphism from the group of C_b which fixes the borel subgroup of C_a.");
        fi;
    od;
    for g in GeneratorsOfGroup(C_b!.group) do
        g_gen := Identity(SymGroup);
        for maxP_type in [1 .. Size(C_a!.types)] do
            if not Image(Image(phi, g), C_a!.subgroups[maxP_type]) in C_a!.subgroups then
                return []; ## Maybe raise error
            else
                sent_type := C_a!.types[Position(C_a!.subgroups, Image(Image(phi, g), C_a!.subgroups[maxP_type]))];
                if sent_type = maxP_type then
                    continue;
                else
                    Add(gens_g_As_Action, (maxP_type,sent_type));
                    if not OnPoints(maxP_type, g_gen) = sent_type then
                        g_gen := (maxP_type,sent_type)*g_gen;
                    fi;
                fi;
            fi;
        od;
        Add(collect_g_gens,g_gen);
    od;
    return [Orbits(Subgroup(SymGroup, gens_g_As_Action)) , collect_g_gens];
end );

InstallMethod( IsIPOAdmissibleTwisting, [IsCosetChamberSystem, IsGroupHomomorphism, IsList, IsGroupHomomorphism], 
    function(C_b, phi, F_set, b_gens_to_perms)
        local rep, J, K, O_J, O_K;
        for rep in F_set do
            for J in Combinations( [1 .. Size(C_b!.types)]) do
                O_J := Orbit(Image(b_gens_to_perms, Subgroup(C_b!.group, Flat(List(J, x -> GeneratorsOfGroup(C_b!.subgroups[x]))))), rep);
                for K in Combinations( [1 .. Size(C_b!.types)]) do
                    if J <> K then 
                    O_K := Orbit(Image(b_gens_to_perms, Subgroup(C_b!.group, Flat(List(K, x -> GeneratorsOfGroup(C_b!.subgroups[x]))))), rep);
                        if Size( Intersection( O_J, O_K ) ) <> Size( Orbit(Image(b_gens_to_perms, Subgroup(C_b!.group, Flat(List(Intersection(J,K), x -> GeneratorsOfGroup(C_b!.subgroups[x]))))), rep) ) then
                            return Error("The twisting is not IPO-admissible. Choose a different set of representatives");
                        fi;
                    fi;
                od;
            od;
        od;
        return true;
    end);

InstallMethod( TwistingCosetChamberSystem, [IsCosetChamberSystem, IsCosetChamberSystem, IsGroupHomomorphism, IsList], 
    function(C_a, C_b, phi, F_set)
    local new_subgroups, phi_set, new_types, b_gens_to_perms, G, B, borel_im, i, rep, l;
    if not IsCosetChamberSystem(C_a) or not IsCosetChamberSystem(C_b) then
        Error("C_a and C_b must be coset chamber systems.");
    fi;
    if not IsSubgroup(AutomorphismGroup(C_a!.group), Image(phi)) then
        Error("phi must be an automorphism of the group of C_a.");
    fi;
    phi_set := PhiTypeSet(C_a, C_b, phi);
    new_types := Union(List(phi_set[1] , x -> ["a", x]), List(C_b!.types, x -> ["b", x]));
    b_gens_to_perms := GroupHomomorphismByImages(C_b!.group, SymmetricGroup(C_a!.types), GeneratorsOfGroup(C_b!.group), phi_set[2]);
    IsIPOAdmissibleTwisting(C_b, phi, F_set, b_gens_to_perms);
    G := SemidirectProduct(C_b!.group, phi, C_a!.group);
    B := Subgroup(G, Union(Image(Embedding(G, 1), GeneratorsOfGroup(C_b!.borel)),
                           Image(Embedding(G, 2), GeneratorsOfGroup(C_a!.borel))));
    borel_im := Image(b_gens_to_perms, C_b!.borel);
    new_subgroups := [];
    for i in new_types do
        if i[1] = "a" then
            rep := Intersection( F_set, i[2]);
            l := Orbit(borel_im, rep)[1];
            Add(new_subgroups, Subgroup(G, Union(Flat(List(l , x -> Image(Embedding(G, 2),GeneratorsOfGroup(C_a!.subgroups[Position(C_a!.types, x)])))), Image(Embedding(G, 1),GeneratorsOfGroup(C_b!.borel)))));
        fi;
    od;
    for i in new_types do
        if i[1] = "b" then
            Add(new_subgroups, Subgroup(G, Union(Image(Embedding(G, 2), GeneratorsOfGroup(C_a!.borel)), Image(Embedding(G, 1), GeneratorsOfGroup(C_b!.subgroups[Position(C_b!.types, i[2])])))));
        fi;
    od;
    Print("New Types: \n");
    for i in [1 .. Size(new_types)] do
        Print("Type ",new_types[i][2], " of ", new_types[i][1], " -> ", i, "\n");
    od;
    return CosetChamberSystem( G, B, new_subgroups, [1 .. Size(new_types)] );
end );