module Tile exposing 
    ( Tile (..)
    , article, base, trashcan
    , position
    , midpoint
    , Msg (..)
    , update
    , view
    )

{-| Stateful element of a `Mosaic`.

@docs Tile, article

# Update
@docs Msg, update

# View
@docs position, midpoint
@docs view
-}

import Tile.Article as Article
import Tile.Interface as Interface
import Gui exposing (Position)




{-| Holds local data of the tile
-}
type Tile
    = Tile Position Kind

type Kind
    = Article {id: Int, data: Article.Article}
    | Trashcan
    | Base

{-|-}
article : String -> Int -> Position -> Tile
article contents id pos =
    Article { id = id, data = Article.singleton contents }
        |> Tile pos

{-|-}
base : Tile
base = Tile midpoint Base

{-|-}
trashcan : Tile
trashcan = Tile midpoint Trashcan

{-|-}
type Msg
    = GotArticleMsg Int Article.Msg

{-|-}
update : Msg -> Tile -> Tile
update msg (Tile pos kind) =
    ( case ( msg, kind ) of
        ( GotArticleMsg key message, Article parameters ) ->
            ( if key == parameters.id 
                then { parameters | data = Article.update message parameters.data }
                else parameters
            ) |> Article
        _ -> kind
    ) |> Tile pos

{-|-}
midpoint : Position
midpoint =
    Position 0 0
{-|-}
position : Tile -> Position
position (Tile pos _) =
    pos






{-|-}
view : Interface.Appearance ( Msg -> msg ) -> Tile -> Gui.Document { mode | expanded : Gui.Mode, collapsed : Gui.Mode } msg
view appearance (Tile pos kind) =
    let mediate_article_message : Int -> (Article.Msg -> Msg)
        mediate_article_message = GotArticleMsg
        inner = 
            case kind of
                Article parameters ->
                    parameters.data 
                        |> Article.view (appearance |> Interface.map_appearance ( mediate_article_message parameters.id ) ) 
                        |> Gui.with_info (String.fromInt parameters.id |> Gui.literal )
                Trashcan ->
                    Gui.collapsed_document (Gui.icon "Trashcan. Move Stuff in here to hide it from the public." "delete") [] []
                Base -> 
                    Gui.collapsed_document (Gui.icon "Canvas!" "aspect_ratio") [] []

    in
    inner
        |> Gui.with_position pos
        |> Gui.with_class "tile"
            




{-

    WHAT        WHEN          WHERE               IF                                              DETAILS

C   CLIPBOARD   ------------------------------------------------------------------------------  To Do.

D   DELTA
    * Move      Drag          Overlay Fill        Not Editing&Selected; not Backdrop.
    * Cancel    ESC           Mosaic
    - Indicate  -             Wrapper             Not Editing; not Backdrop.                      Mosaic delta
    
E   EDITING
    * Open      DoubleClick   Wrapper             Not Editing                         
    * Close     ESC           Mosaic              Editing

F   FOCUS
    * Reset     Drag          Overlay Fill        Not Editing&Selected.
    - Indicate  -             Overlay Fill        Not Backdrop.                                   Focused?
  
I   INFLUENCE  
    - Receive   -             Influenced Tile     Influencable Tile, overlaps with                Tiles a & b 
    `                                              influencing tile.
  
O   OVERLAP  
    * Swap      Click         Overlay Button      Not Editing; Not Backdrop; overlaps with        Delta to other tile
    `                          on higher tile      another Non-Backdrop.
  
P   POSITION  
    - Assign    -             Wrapper             Not Backdrop.                                   Tile position
  
R   REGION  
    * Draw      Drag          Wrapper             Backdrop.
  
S   SELECTION                    
    * Toggle    Click         Overlay Button      >1 tile selected; not Editing; not Backdrop.    Selected?
    - Indicate  -             Overlay Fill        Not Backdrop.                                   Selected?
  
    * Cancel    ESC           Mosaic

T   TILE
    - Draw                                          Appearance : Normal | Selected | Interactive how_to_message

U   To do: UNDO
\

-}



{-
article context data =
    { drag = 
    }

type alias Configuration context State data =
    { drag : Drag
    , face : Face context data
    , edit : data
    , role : Role
    , tool : Tool a
    }

type Drag
    = ToMove
    | ToSelect

type Face context data
    = Contextual ( context -> data -> Ui.Face )
    | Symbolic ( data -> Ui.Face )

type Tool trashable editable
    = Unit
    | Trash ( Undoable ( List trashable ) )
    | Veil
    | Edit editable

type alias Color =
    String

type alias Undoable a =
    { done : List { operation : a }, undone : List { operation : a } }

    -}