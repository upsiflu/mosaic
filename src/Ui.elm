module Ui exposing
    (  Face
       -- create:

    , Option(..)
    , Overlay
    , Ui(..)
    , attributes_when
    , conditional_attributes
    , decorate_with
    , face
    ,  html_when
       -- view:

    , icon
    , placeholder
    ,  preview
       -- map:

    , text
    , viewButton
    , viewToolbar
    ,  withHint
       -- compose:

    , wrap_with
    )

-- Convenience functions for buttons, toolbars and stuff
-- For example, buttons must not contain interactive elements.

import Html exposing (Html, br, div, h1, h2, h3, img, option, pre, select, span, strong, text)
import Html.Attributes exposing (attribute, class, classList, id, src, title, value)
import Html.Attributes.Extra as Attributes
import Html.Events exposing (onClick)
import Html.Extra as Html



-- Wrap Html to explicate whether it's interactive.of


type Ui msg
    = Static (List (Html Never))
    | Active (List (Html msg))


type alias Overlay msg =
    List (Html msg)


placeholder : String -> Ui msg
placeholder str =
    Static [ Html.span [ class "placeholder" ] [ Html.text str ] ]


type alias Wrapper msg =
    List (Html msg) -> Html msg


wrap_with : Wrapper msg -> Ui msg -> Html msg
wrap_with wrapper ui =
    case ui of
        Static contents ->
            List.map Html.static contents |> wrapper

        Active contents ->
            contents |> wrapper


decorate_with : Overlay msg -> Ui msg -> Ui msg
decorate_with overlay ui =
    case ui of
        Static contents ->
            overlay ++ List.map Html.static contents |> Active

        Active contents ->
            overlay ++ contents |> Active



-- Anything that is interactive.
-- Each Option has a Face.


type Option msg
    = Toggle Face { toggle : msg, is_on : Bool }
    | Input Face { set : String -> msg, is_on : Bool }
    | Compose Face (List (Option msg))



-- Create Face (not to confuse with Html.face!)
-- Faces can't be interactive.


type Face
    = Face String (Html Never)


preview : String -> String -> List (Html Never) -> Face
preview hint name samples =
    span [ class "preview", class "static" ] [ span [ class name, class "static" ] samples ]
        |> Face hint


face : String -> String -> Face
face hint string =
    text string
        |> Face hint


icon : String -> String -> Face
icon hint string =
    span [ class "icon", class "static" ] [ span [ class "static material-icons" ] [ text string ] ]
        |> Face hint


withHint : String -> Face -> Face
withHint hint (Face _ html) =
    Face hint html


text : String -> Html Never
text =
    Html.text


viewToolbar : String -> List (Option msg) -> Html msg
viewToolbar name =
    List.map
        viewButton
        >> div [ class "toolbar", class name ]



-- all directly interactive objects get the class .interactive.


viewButton : Option msg -> Html msg
viewButton option =
    case option of
        Toggle l t ->
            viewFaceed l
                [ onClick t.toggle, classList [ ( "on", t.is_on ) ] ]
                Html.button

        _ ->
            Html.nothing


viewFaceed : Face -> List (Html.Attribute msg) -> (List (Html.Attribute msg) -> List (Html msg) -> Html msg) -> Html msg
viewFaceed l interaction element =
    let
        ( static_content, static_attributes ) =
            case l of
                Face hint html ->
                    ( [ span [ class "face" ] [ html ] ], [ Html.Attributes.title hint ] )
                        |> Tuple.mapBoth (List.map Html.static) (List.map Attributes.static)
    in
    element
        (class "interactive" :: interaction ++ static_attributes)
        static_content


conditional_attributes : List ( Html.Attribute msg, Bool ) -> List (Html.Attribute msg)
conditional_attributes =
    List.map
        (\( attribute, condition ) ->
            if condition then
                attribute

            else
                class ""
        )


attributes_when : Bool -> List (Html.Attribute msg) -> List (Html.Attribute msg)
attributes_when  condition attribs =
    if condition then
        attribs

    else
        []


html_when : Bool -> Html msg -> Html msg
html_when condition elems  =
    if condition then
        elems

    else
        Html.nothing
