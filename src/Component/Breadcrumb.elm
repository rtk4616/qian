module Component.Breadcrumb exposing (render)

{-| This module is a component to display a breadcrumb from a path
-}

import Message exposing (Message(..))
import File exposing (PathMember(..))
import Component.Helper exposing (icon)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Html
    exposing
        ( Html
        , text
        , div
        , span
        , a
        )


{-| Render the breadcrumb.
-}
render : File.Path -> Html Message
render currentPath =
    let
        crumbs =
            File.expandPath currentPath
    in
        div
            [ Attr.class "breadcrumb" ]
            (List.map (mapCrumb currentPath) crumbs)


{-| Render a specific crumb (wrapped in a Html.span)
-}
mapCrumb : File.Path -> File.ExpandedPath -> Html Message
mapCrumb currentPath crumb =
    span
        [ Attr.class "crumb" ]
        (renderCrumb currentPath crumb)


{-| Render a crumb (as a link or not)
-}
renderCrumb : File.Path -> File.ExpandedPath -> List (Html Message)
renderCrumb currentPath crumb =
    if currentPath == crumb.absolute then
        [ span
            [ Attr.class "current" ]
            [ pathMemberToText crumb ]
        ]
    else
        [ a
            [ onClick (ChangeDir crumb.absolute) ]
            [ pathMemberToText crumb ]
        , icon "angle-right"
        ]


{-| render a PathMember as a String
-}
pathMemberToText : File.ExpandedPath -> Html Message
pathMemberToText expandedPathFile =
    case expandedPathFile.relative of
        Root ->
            text "Root"

        Member name ->
            text name
