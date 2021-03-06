module File
    exposing
        ( Path
        , Tree
        , ExpandedPath
        , PathMember(..)
        , Item
        , expandPath
        , split
        , join
        , trailSlashes
        , parent
        )

{-| Some helpers to deal with files !
-}


{-| This type is for representing a Path foo/bar/baz.
-}
type alias Path =
    String


{-| This type is for representing a member of a Path.
-}
type PathMember
    = Root
    | Member Path


{-| This type is for representing a path with relative and absolute name.
In fact, it is useful for the Breadcrumb !
-}
type alias ExpandedPath =
    { relative : PathMember
    , absolute : Path
    }


{-| Represents a file coming from the Finder
-}
type alias Item =
    { name : String
    , path : Path
    , directory : Bool
    , hidden : Bool
    }


{-| Represent a list of File from the Finder
-}
type alias Tree =
    List Item


trailSlashes : Path -> Path
trailSlashes path =
    let
        trimed =
            String.trim path

        left =
            if String.endsWith "/" trimed then
                String.dropRight 1 trimed
            else
                trimed
    in
        left


{-| Join differents path into an unique path
-}
join : List Path -> Path
join members =
    case members of
        [] ->
            "/"

        [ x ] ->
            x ++ "/"

        _ :: _ ->
            members
                |> List.map trailSlashes
                |> String.join "/"


{-| Split Path into a list of path
-}
split : Path -> List Path
split path =
    String.split "/" path


{-| Convert a Path to an expandable path
-}
expandPath : Path -> List ExpandedPath
expandPath path =
    path
        |> split
        |> (List.foldl expander [])
        |> List.reverse


{-| Reducer to split path in an expanded Path
-}
expander : Path -> List ExpandedPath -> List ExpandedPath
expander element path =
    case path of
        [] ->
            [ { relative = Root, absolute = "/" } ]

        x :: xs ->
            { relative = Member element
            , absolute = join [ x.absolute, element ]
            }
                :: path


{-| Get the parent of a file
-}
parent : Path -> Maybe Path
parent path =
    case List.reverse (split path) of
        "" :: "" :: _ ->
            Nothing

        x :: y :: tl ->
            (y :: tl)
                |> List.reverse
                |> join
                |> Just

        _ ->
            Nothing
