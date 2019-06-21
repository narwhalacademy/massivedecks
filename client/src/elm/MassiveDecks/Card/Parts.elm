module MassiveDecks.Card.Parts exposing
    ( Part(..)
    , Parts
    , Transform(..)
    , fromList
    , map
    , slotCount
    , unsafeFromList
    , view
    , viewFilled
    , viewSingleLine
    )

import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Attributes.Aria as Aria
import MassiveDecks.Util.String as String


{-| A transform to apply to the value in a slot.
-}
type Transform
    = UpperCase
    | Capitalize
    | None


{-| A part of a call's text. This is either just text or a position for a call to be inserted in-game.
-}
type Part
    = Text String
    | Slot Transform


{-| Represents a line as a part of a part. Between each one the text will be forced to line break.
-}
type alias Line =
    List Part


{-| A collection of `Line`s. It is guaranteed to have at least one `Slot`.
-}
type Parts
    = Parts (List Line)


{-| A predicate checking if a part is a slot.
-}
isSlot : Part -> Bool
isSlot part =
    case part of
        Text _ ->
            False

        Slot _ ->
            True


{-| Construct a `Parts` from a `List` of `Line`s. This will fail if there is not at least one `Slot`.
-}
fromList : List Line -> Maybe Parts
fromList lines =
    if List.any (List.any isSlot) lines then
        Just (Parts lines)

    else
        Nothing


{-| TODO: Remove
-}
unsafeFromList : List Line -> Parts
unsafeFromList lines =
    Parts lines


{-| Apply the given function to each `Part`, returning the resulting `List`.
-}
map : (Line -> a) -> Parts -> List a
map f lines =
    lines |> extract |> List.map f


{-| The number of `Slot`s in the `Parts`. This will be one or more.
-}
slotCount : Parts -> Int
slotCount lines =
    lines |> extract |> List.concat |> List.filter isSlot |> List.length


{-| Render the `Parts` to HTML.
-}
view : Parts -> List (Html msg)
view parts =
    viewFilled [] parts


viewSingleLine : Parts -> List (Html msg)
viewSingleLine (Parts lines) =
    lines |> List.concat |> viewParts []


{-| Render the `Parts` with slots filled with the given values.
-}
viewFilled : List String -> Parts -> List (Html msg)
viewFilled play (Parts lines) =
    viewLines play lines



{- Private -}


viewLines : List String -> List Line -> List (Html msg)
viewLines play lines =
    case lines of
        firstLine :: restLines ->
            let
                slots =
                    firstLine |> List.filter isSlot |> List.length
            in
            (viewParts (List.take slots play) firstLine |> Html.p []) :: viewLines (List.drop slots play) restLines

        [] ->
            []


viewParts : List String -> List Part -> List (Html msg)
viewParts play parts =
    case parts of
        firstPart :: restParts ->
            case firstPart of
                Text string ->
                    viewText False string ++ viewParts play restParts

                Slot transform ->
                    case play of
                        firstPlay :: restPlay ->
                            viewText True (applyTransform transform firstPlay) ++ viewParts restPlay restParts

                        [] ->
                            Html.span [ HtmlA.class "slot" ] [] :: viewParts [] restParts

        [] ->
            []


applyTransform : Transform -> String -> String
applyTransform transform value =
    case transform of
        UpperCase ->
            String.toUpper value

        Capitalize ->
            String.capitalise value

        None ->
            value


viewText : Bool -> String -> List (Html msg)
viewText slot string =
    let
        words =
            string |> splitWords |> List.map (\word -> Html.span [] [ Html.text word ])
    in
    if slot then
        [ Html.span [ HtmlA.class "slot" ] words ]

    else
        words


splitWords : String -> List String
splitWords string =
    case String.uncons string of
        Nothing ->
            []

        Just ( first, rest ) ->
            case first of
                ' ' ->
                    String.fromChar first :: splitWords rest

                other ->
                    case splitWords rest of
                        [] ->
                            [ String.fromChar other ]

                        head :: tail ->
                            String.cons other head :: tail


extract : Parts -> List Line
extract lines =
    case lines of
        Parts list ->
            list
