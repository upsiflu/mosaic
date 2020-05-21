module Zip exposing
    ( IntPath
    , Path(..)
    , Wing(..)
    , Zip
    , focus
    , fold
    , fold_homogenous
    , foldl
    , foldl_homogenous
    , foldl_left_side
    , foldl_right_side
    , foldr
    , foldr_homogenous
    , foldr_left_side
    , foldr_right_side
    , indexed_map_focus
    , indexed_map_periphery
    , insert_left
    , insert_right
    , int_to_path
    , left
    , length
    , map_focus
    , map_periphery
    , path_to_int
    , path_to_string
    , reverse
    , right
    , singleton
    , to_string
    , walk
    )

{- A Zipper over a List.

   Use this structure to model a collection of linearly connected items where one (the "focus") is special,
   and where you can walk left and right to make another one special.

    - wraps on the left and right edges; thus every path is legal.
    - focus and periphery have distinct data types.

-}


type Zip c a
    = Zip (List a) c (List a)


type Path
    = L Path
    | R Path
    | Here


type alias IntPath =
    Int


type Wing
    = Left
    | Right


length : Zip c a -> Int
length (Zip l _ r) =
    List.length l + 1 + List.length r


focus : Zip c a -> c
focus (Zip _ c _) =
    c


singleton : c -> Zip c a
singleton c =
    Zip [] c []


insert_right : a -> Zip c a -> Zip c a
insert_right a (Zip l c r) =
    Zip l c (a :: r)


insert_left : a -> Zip c a -> Zip c a
insert_left a (Zip l c r) =
    Zip (a :: l) c r



-- wrap around the edges.


left : (c -> a) -> (a -> c) -> Zip c a -> Zip c a
left ca ac ((Zip l c r) as original) =
    case ( l, List.reverse r ) of
        ( [], [] ) ->
            original

        ( [], ri :: ght ) ->
            Zip (ght ++ [ ca c ]) (ac ri) []

        ( le :: ft, _ ) ->
            Zip ft (ac le) (ca c :: r)


right : (c -> a) -> (a -> c) -> Zip c a -> Zip c a
right ca ac ((Zip l c r) as original) =
    case ( List.reverse l, r ) of
        ( [], [] ) ->
            original

        ( le :: ft, [] ) ->
            Zip [] (ac le) (ft ++ [ ca c ])

        ( _, ri :: ght ) ->
            Zip (ca c :: l) (ac ri) ght


map_focus : (c -> d) -> Zip c a -> Zip d a
map_focus cd (Zip l c r) =
    Zip l (cd c) r


indexed_map_focus : (Int -> c -> d) -> Zip c a -> Zip d a
indexed_map_focus icd (Zip l c r) =
    Zip l (icd 0 c) r


map_periphery : (a -> b) -> Zip c a -> Zip c b
map_periphery ab (Zip l c r) =
    Zip (List.map ab l) c (List.map ab r)


indexed_map_periphery : (Int -> a -> b) -> Zip c a -> Zip c b
indexed_map_periphery iab (Zip l c r) =
    Zip (List.indexedMap (negate >> iab) l) c (List.indexedMap iab r)


foldl : { focus : c -> b -> b, periphery : a -> b -> b } -> b -> Zip c a -> b
foldl fu acc (Zip l c r) =
    List.foldl fu.periphery acc l
        |> fu.focus c
        |> (\done -> List.foldl fu.periphery done r)


fold : { focus : c -> b -> b, periphery : a -> b -> b } -> b -> Zip c a -> b
fold fu acc (Zip l c r) =
    List.foldr fu.periphery acc l
        |> fu.focus c
        |> (\done -> List.foldl fu.periphery done r)


foldr : { focus : c -> b -> b, periphery : a -> b -> b } -> b -> Zip c a -> b
foldr fu acc =
    reverse >> foldl fu acc


foldl_left_side : (a -> b -> b) -> b -> Zip c a -> b
foldl_left_side acc primer (Zip l _ _) =
    List.foldl acc primer l


foldl_right_side : (a -> b -> b) -> b -> Zip c a -> b
foldl_right_side acc primer (Zip _ _ r) =
    List.foldl acc primer r


foldr_left_side : (a -> b -> b) -> b -> Zip c a -> b
foldr_left_side acc primer (Zip l _ _) =
    List.foldr acc primer l


foldr_right_side : (a -> b -> b) -> b -> Zip c a -> b
foldr_right_side acc primer (Zip _ _ r) =
    List.foldr acc primer r


foldl_homogenous : (a -> b -> b) -> b -> Zip a a -> b
foldl_homogenous fu =
    foldl { focus = fu, periphery = fu }


fold_homogenous : (a -> b -> b) -> b -> Zip a a -> b
fold_homogenous fu =
    fold { focus = fu, periphery = fu }


foldr_homogenous : (a -> b -> b) -> b -> Zip a a -> b
foldr_homogenous fu =
    foldr { focus = fu, periphery = fu }


reverse : Zip c a -> Zip c a
reverse (Zip l c r) =
    Zip (List.reverse r) c (List.reverse l)


walk : (c -> a) -> (a -> c) -> Path -> Zip c a -> Zip c a
walk ca ac p =
    case p of
        Here ->
            identity

        L rest ->
            left ca ac >> walk ca ac rest

        R rest ->
            right ca ac >> walk ca ac rest


path_to_string : Path -> String
path_to_string p =
    case p of
        Here ->
            ""

        L rest ->
            "L" ++ path_to_string rest

        R rest ->
            "R" ++ path_to_string rest


path_to_int : Path -> IntPath
path_to_int p =
    case p of
        Here ->
            0

        L rest ->
            path_to_int rest - 1

        R rest ->
            path_to_int rest + 1


int_to_path : IntPath -> Path
int_to_path i =
    if i < 0 then
        L <| int_to_path (i + 1)

    else if i > 0 then
        R <| int_to_path (i - 1)

    else
        Here


to_string : Zip c a -> String
to_string (Zip l _ r) =
    String.repeat (List.length l) " L <-" ++ " 0 " ++ String.repeat (List.length r) "-> R "
