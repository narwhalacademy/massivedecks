module MassiveDecks.Pages.Start.Model exposing
    ( LobbyCreation
    , Model
    )

import MassiveDecks.Pages.Lobby.GameCode as GameCode exposing (GameCode)
import MassiveDecks.Pages.Lobby.Model as Lobby
import MassiveDecks.Pages.Start.LobbyBrowser.Model as LobbyBrowser
import MassiveDecks.Pages.Start.Route exposing (Route)
import MassiveDecks.Requests.HttpData.Model as HttpData exposing (HttpData)
import MassiveDecks.User as User


{-| Data for the start page.
-}
type alias Model =
    { route : Route
    , lobbies : LobbyBrowser.Model
    , name : String
    , gameCode : Maybe GameCode
    , newLobbyRequest : HttpData Lobby.Auth
    , joinLobbyRequest : HttpData Lobby.Auth
    }


{-| A request to create a new lobby.
-}
type alias LobbyCreation =
    { owner : User.Registration
    }
