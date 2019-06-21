module MassiveDecks.Game.Round.Playing exposing
    ( init
    , view
    )

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import MassiveDecks.Card as Card
import MassiveDecks.Card.Model as Card
import MassiveDecks.Game.Action.Model as Action
import MassiveDecks.Game.Messages as Game
import MassiveDecks.Game.Model exposing (..)
import MassiveDecks.Game.Player as Player
import MassiveDecks.Game.Round as Round
import MassiveDecks.Messages as Global
import MassiveDecks.Model exposing (..)
import MassiveDecks.Pages.Lobby.Configure.Model as Configure
import MassiveDecks.Pages.Lobby.Messages as Lobby
import MassiveDecks.Pages.Lobby.Model as Lobby
import MassiveDecks.Strings as Strings
import MassiveDecks.User as User
import MassiveDecks.Util.List as List
import MassiveDecks.Util.Random as Random
import Random
import Set exposing (Set)


init : Round.Playing -> Round.Pick -> ( Round.Playing, Cmd Global.Msg )
init round pick =
    let
        cmd =
            round.players
                |> playStylesGenerator (Card.slotCount round.call)
                |> Random.generate (Game.SetPlayStyles >> lift)
    in
    ( { round | pick = pick }
    , cmd
    )


view : Shared -> Lobby.Auth -> List Configure.Deck -> Model -> Round.Playing -> RoundView Global.Msg
view shared auth decks model round =
    let
        slots =
            Card.slotCount round.call

        missingFromPick =
            slots - (round.pick.cards |> List.length)

        ( action, instruction, notPlaying ) =
            if Player.isCzar (Round.P round) auth.claims.uid then
                ( Nothing, Strings.CzarsDontPlayInstruction, True )

            else
                case round.pick.state of
                    Round.Selected ->
                        if missingFromPick > 0 then
                            ( Nothing, Strings.PlayInstruction { numberOfCards = missingFromPick }, False )

                        else
                            ( Just Action.Submit, Strings.SubmitInstruction, False )

                    Round.Submitted ->
                        ( Just Action.TakeBack, Strings.WaitingForPlaysInstruction, True )

        hand =
            Html.div [ HtmlA.classList [ ( "hand", True ), ( "not-playing", notPlaying ) ] ]
                (model.hand |> List.map (round.pick.cards |> viewHandCard shared decks))

        backgroundPlays =
            Html.div [ HtmlA.class "background-plays" ]
                (round.players |> Set.toList |> List.map (viewBackgroundPlay model.playStyles slots round.played))

        picked =
            round.pick.cards
                |> List.map (\id -> List.find (\c -> c.details.id == id) model.hand)
                |> List.filterMap identity
    in
    { instruction = Just instruction
    , action = action
    , content =
        Html.div []
            [ hand
            , backgroundPlays
            ]
    , fillCallWith = picked
    }



{- Private -}


viewHandCard : Shared -> List Configure.Deck -> List Card.Id -> Card.Response -> Html Global.Msg
viewHandCard shared decks picked response =
    Card.view
        shared
        decks
        Card.Front
        [ HtmlA.classList [ ( "picked", List.member response.details.id picked ) ]
        , response.details.id |> Game.Pick |> lift |> HtmlE.onClick
        ]
        (Card.R response)


viewBackgroundPlay : PlayStyles -> Int -> Set User.Id -> User.Id -> Html msg
viewBackgroundPlay playStyles slots played for =
    let
        -- TODO: Move to css variable --rotation when possible.
        cards =
            playStyles
                |> Dict.get for
                |> Maybe.withDefault (List.repeat slots { rotation = 0 })
                |> List.map viewBackgroundPlayCard
    in
    Html.div [ HtmlA.classList [ ( "play", True ), ( "played", Set.member for played ) ] ] cards


viewBackgroundPlayCard : CardStyle -> Html msg
viewBackgroundPlayCard playStyle =
    Card.viewUnknownResponse [ "rotate(" ++ String.fromFloat playStyle.rotation ++ "turn)" |> HtmlA.style "transform" ]


lift : Game.Msg -> Global.Msg
lift msg =
    msg |> Lobby.GameMsg |> Global.LobbyMsg


playStylesGenerator : Int -> Set User.Id -> Random.Generator PlayStyles
playStylesGenerator cards players =
    Random.map Dict.fromList
        (players |> Set.toList |> List.map (playStylesEntryGenerator cards) |> Random.disparateList)


playStylesEntryGenerator : Int -> User.Id -> Random.Generator ( User.Id, List CardStyle )
playStylesEntryGenerator cards userId =
    Random.map (\playStyles -> ( userId, playStyles ))
        (Random.list cards playStyleGenerator)


playStyleGenerator : Random.Generator CardStyle
playStyleGenerator =
    Random.map CardStyle
        (Random.float 0 1)
