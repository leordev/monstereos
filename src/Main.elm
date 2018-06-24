port module Main exposing (..)

import Date.Distance as Distance
import Date
import Html exposing (..)
import Html.Attributes exposing (attribute, class, defaultValue, href, placeholder, target, type_, value, datetime, alt, src, max, style)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as JD
import Time
import Json.Decode.Pipeline as JDP
import Date.Extra.Format as DateFormat
import Date.Extra.Config.Config_en_us as DateConfig


-- import Json.Encode as JE
-- import FormatNumber
-- import FormatNumber.Locales exposing (usLocale)


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            initModel flags

        cmd =
            if not (String.isEmpty model.user.eosAccount) then
                ( { model | isLoading = True }
                , Cmd.none
                  -- Cmd.batch [ listExchanges model ]
                  --, getWatchList model ]
                )
            else
                ( model, Cmd.none )
    in
        cmd


initialModel : Model
initialModel =
    { isLoading = False
    , isMuted = False
    , scatterInstalled = False
    , scatterInstallPressed = False
    , showHelp = False
    , showMonsterCreation = False
    , showMonsterTransfer = False
    , user = User "" ""
    , error = Nothing
    , content = Home
    , socketsConnected = False
    , currentTime = 0
    , monsters = []
    , newMonsterName = ""
    , petIdForTransfer = 0
    , newOwnerAccount = ""
    , notifications = []
    , wallet = Wallet 0
    , depositAmount = 3
    , showWallet = False
    , globalConfig = initialConfig
    , currentRankPage = 0
    }


initModel : Flags -> Model
initModel flags =
    let
        content =
            if not (String.isEmpty flags.user.eosAccount) then
                MyMonsters
            else
                Home
    in
        { initialModel | user = flags.user, content = content }


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- Model


type NotificationType
    = Success String
    | Warning String
    | Error String


type MonsterRequest
    = Feed
    | Awake
    | Sleep
    | Play
    | Wash


type Content
    = Home
    | MyMonsters
    | Rank
    | About


type alias Flags =
    { user : User
    }


type alias User =
    { eosAccount : String
    , publicKey : String
    }


type alias GlobalConfig =
    { lastId : Int
    , creationFee : String
    , maxHealth : Int
    , hungerToZero : Int
    , minHungerInterval : Int
    , maxHungerPoints : Int
    , hungerHpModifier : Int
    , minAwakeInterval : Int
    , minSleepPeriod : Int
    , creationTolerance : Int
    , monstersToActivateFee : Int
    }


initialConfig : GlobalConfig
initialConfig =
    { lastId = 0
    , creationFee = "0.0000 EOS"
    , maxHealth = 0
    , hungerToZero = 0
    , minHungerInterval = 0
    , maxHungerPoints = 0
    , hungerHpModifier = 0
    , minAwakeInterval = 0
    , minSleepPeriod = 0
    , creationTolerance = 0
    , monstersToActivateFee = 0
    }


type alias Monster =
    { id : Int
    , owner : String
    , new_owner: String
    , name : String
    , mtype : Int
    , created_at : Time.Time
    , death_at : Time.Time
    , health : Int
    , hunger : Int
    , last_fed_at : Time.Time
    , awake : Int
    , is_sleeping : Bool
    , last_bed_at : Time.Time
    , last_awake_at : Time.Time
    , happiness : Int
    , last_play_at : Time.Time
    , clean : Int
    , last_shower_at : Time.Time
    }


type alias Wallet =
    { funds : Float }


type alias Notification =
    { notification : NotificationType
    , time : Time.Time
    , id : String
    }


type alias Model =
    { isLoading : Bool
    , isMuted : Bool
    , showHelp : Bool
    , showMonsterCreation : Bool
    , showMonsterTransfer : Bool
    , scatterInstalled : Bool
    , scatterInstallPressed : Bool
    , user : User
    , error : Maybe String
    , content : Content
    , socketsConnected : Bool
    , currentTime : Time.Time
    , monsters : List Monster
    , newMonsterName : String
    , petIdForTransfer: Int
    , newOwnerAccount : String
    , notifications : List Notification
    , wallet : Wallet
    , showWallet : Bool
    , depositAmount : Float
    , globalConfig : GlobalConfig
    , currentRankPage : Int
    }



-- Helper Constants


monsterMinFeedInterval : Float
monsterMinFeedInterval =
    -- TODO: move it to chain and make it dynamic so frontends are all aligned?
    3 * Time.hour


monsterMinAwakeInterval : Float
monsterMinAwakeInterval =
    -- TODO: move it to chain and make it dynamic so frontends are all aligned?
    8 * Time.hour


monsterMinSleepPeriod : Float
monsterMinSleepPeriod =
    -- TODO: move it to chain and make it dynamic so frontends are all aligned?
    4 * Time.hour


scatterExtensionLink : String
scatterExtensionLink =
    "https://chrome.google.com/webstore/detail/scatter/ammjpmhgckkpcamddpolhchgomcojkle"


jungleTestNetLink : String
jungleTestNetLink =
    "http://dev.cryptolions.io"



-- Ports


port signOut : () -> Cmd msg


port setTitle : String -> Cmd msg


port listMonsters : () -> Cmd msg


port setMonsters : (JD.Value -> msg) -> Sub msg


port setMonstersFailed : (String -> msg) -> Sub msg


port getGlobalConfig : () -> Cmd msg


port setGlobalConfig : (JD.Value -> msg) -> Sub msg


port setGlobalConfigFailed : (String -> msg) -> Sub msg


port getWallet : () -> Cmd msg


port setWallet : (JD.Value -> msg) -> Sub msg


port setWalletFailed : (String -> msg) -> Sub msg


port submitNewMonster : String -> Cmd msg


port monsterCreationSucceed : (String -> msg) -> Sub msg


port monsterCreationFailed : (String -> msg) -> Sub msg


port requestFeed : Int -> Cmd msg


port requestPlay : Int -> Cmd msg


port requestWash : Int -> Cmd msg


port requestBed : Int -> Cmd msg


port requestDelete : Int -> Cmd msg


port requestAwake : Int -> Cmd msg


port feedSucceed : (String -> msg) -> Sub msg


port feedFailed : (String -> msg) -> Sub msg


port depositSucceed : (String -> msg) -> Sub msg


port depositFailed : (String -> msg) -> Sub msg


port requestDeposit : Float -> Cmd msg


port bedSucceed : (String -> msg) -> Sub msg


port bedFailed : (String -> msg) -> Sub msg


port deleteSucceed : (String -> msg) -> Sub msg


port deleteFailed : (String -> msg) -> Sub msg


port awakeSucceed : (String -> msg) -> Sub msg


port awakeFailed : (String -> msg) -> Sub msg

port submitNewOwner : (Int, String) -> Cmd msg

port transferSucceed : (String -> msg) -> Sub msg

port transferFailed : (String -> msg) -> Sub msg

port requestClaim : Int -> Cmd msg

port claimSucceed : (String -> msg) -> Sub msg

port claimFailed : (String -> msg) -> Sub msg

port setScatterInstalled : (Bool -> msg) -> Sub msg


port scatterRequestIdentity : () -> Cmd msg


port scatterRejected : (String -> msg) -> Sub msg


port setScatterIdentity : (JD.Value -> msg) -> Sub msg


port refreshPage : () -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every Time.second Tick
        , Time.every Time.minute RefreshData
        , setScatterIdentity ScatterSignIn
        , setScatterInstalled ScatterLoaded
        , scatterRejected ScatterRejection
        , setMonsters SetMonsters
        , setMonstersFailed SetMonstersFailure
        , setWallet SetWallet
        , setWalletFailed SetWalletFailure
        , setGlobalConfig SetGlobalConfig
        , setGlobalConfigFailed SetGlobalConfigFailure
        , depositSucceed DepositSucceed
        , depositFailed DepositFailed
        , feedFailed MonsterFeedFailed
        , feedSucceed MonsterFeedSucceed
        , awakeFailed MonsterAwakeFailed
        , awakeSucceed MonsterAwakeSucceed
        , bedFailed MonsterBedFailed
        , bedSucceed MonsterBedSucceed
        , deleteFailed MonsterDeleteFailed
        , deleteSucceed MonsterDeleteSucceed
        , monsterCreationSucceed MonsterCreationSucceed
        , monsterCreationFailed MonsterCreationFailed
        , transferSucceed MonsterTransferSucceed
        , transferFailed MonsterTransferFailed
        , claimSucceed MonsterClaimSucceed
        , claimFailed MonsterClaimFailed
        ]



-- update


type Msg
    = Tick Time.Time
    | SetContent Content
    | ScatterLoaded Bool
    | ScatterSignIn JD.Value
    | RefreshPage
    | RefreshData Time.Time
    | ScatterRequestIdentity
    | ScatterInstallPressed
    | ScatterRejection String
    | SetWallet JD.Value
    | SetWalletFailure String
    | SetGlobalConfig JD.Value
    | SetGlobalConfigFailure String
    | DepositSucceed String
    | DepositFailed String
    | RequestDeposit Float
    | SetMonsters JD.Value
    | SetMonstersFailure String
    | MonsterFeedSucceed String
    | MonsterFeedFailed String
    | MonsterAwakeSucceed String
    | MonsterAwakeFailed String
    | MonsterBedSucceed String
    | MonsterBedFailed String
    | MonsterDeleteSucceed String
    | MonsterDeleteFailed String
    | MonsterCreationSucceed String
    | MonsterCreationFailed String
    | RequestMonsterFeed Int
    | RequestMonsterPlay Int
    | RequestMonsterBed Int
    | RequestMonsterAwake Int
    | RequestMonsterDelete Int
    | RequestMonsterWash Int
    | RequestMonsterTransfer Int
    | UpdateNewOwnerAccount String
    | SubmitTransferMonster
    | MonsterTransferSucceed String
    | MonsterTransferFailed String 
    | MonsterClaimSucceed String
    | MonsterClaimFailed String
    | RequestMonsterClaim Int
    | UpdateNewMonsterName String
    | SubmitNewMonster
    | UpdateDepositAmount String
    | SubmitDeposit
    | UpdateCurrentRankPage String
    | ToggleHelp
    | ToggleWallet
    | ToggleMonsterCreation
    | ToggleMonsterTransfer
    | DeleteNotification String
    | Logout


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScatterLoaded isLoaded ->
            ( { model | scatterInstalled = isLoaded }, Cmd.none )

        ScatterInstallPressed ->
            ( { model | scatterInstallPressed = True }, Cmd.none )

        ScatterRequestIdentity ->
            ( { model | isLoading = True }, scatterRequestIdentity () )

        ScatterRejection txt ->
            ( { model
                | isLoading = False
                , notifications = [ Notification (Error ("Scatter Rejection: " ++ txt)) model.currentTime (toString model.currentTime) ] ++ model.notifications
              }
            , Cmd.none
            )

        RefreshData _ ->
            ( model, Cmd.batch [ getWallet (), getGlobalConfig () ] )

        RequestMonsterFeed petId ->
            let
                warnNotification =
                    handleMonsterRequest model Feed petId
            in
                case warnNotification of
                    Just notification ->
                        ( { model
                            | notifications = notification :: model.notifications
                          }
                        , Cmd.none
                        )

                    Nothing ->
                        ( { model | isLoading = True }, requestFeed (petId) )

        MonsterFeedSucceed trxId ->
            handleMonsterAction model trxId "Feed" True

        MonsterFeedFailed err ->
            handleMonsterAction model err "Feed" False

        DepositSucceed trxId ->
            handleActionResponse
                { model | showWallet = False }
                trxId
                "Deposit"
                True

        DepositFailed err ->
            handleActionResponse model err "Deposit" False

        RequestDeposit amount ->
            ( { model | isLoading = True }, requestDeposit (amount) )

        RequestMonsterPlay petId ->
            ( { model | isLoading = True }, requestPlay (petId) )

        RequestMonsterWash petId ->
            ( { model | isLoading = True }, requestWash (petId) )

        RequestMonsterBed petId ->
            let
                warnNotification =
                    handleMonsterRequest model Sleep petId
            in
                case warnNotification of
                    Just notification ->
                        ( { model
                            | notifications = notification :: model.notifications
                          }
                        , Cmd.none
                        )

                    Nothing ->
                        ( { model | isLoading = True }, requestBed (petId) )

        MonsterBedSucceed trxId ->
            handleMonsterAction model trxId "Bed" True

        MonsterBedFailed err ->
            handleMonsterAction model err "Bed" False

        RequestMonsterDelete petId ->
            ( { model | isLoading = True }, requestDelete (petId) )

        MonsterDeleteSucceed trxId ->
            handleMonsterAction model trxId "Delete" True

        MonsterDeleteFailed err ->
            handleMonsterAction model err "Delete" False

        RequestMonsterAwake petId ->
            let
                warnNotification =
                    handleMonsterRequest model Awake petId
            in
                case warnNotification of
                    Just notification ->
                        ( { model
                            | notifications = notification :: model.notifications
                          }
                        , Cmd.none
                        )

                    Nothing ->
                        ( { model | isLoading = True }, requestAwake (petId) )

        MonsterAwakeSucceed trxId ->
            handleMonsterAction model trxId "Awake" True

        MonsterAwakeFailed err ->
            handleMonsterAction model err "Awake" False

        MonsterCreationSucceed trxId ->
            ( { model
                | isLoading = False
                , showMonsterCreation = False
                , newMonsterName = ""
                , notifications = [ Notification (Success ("Monster  " ++ model.newMonsterName ++ " Created! TrxId: " ++ trxId)) model.currentTime (toString model.currentTime) ] ++ model.notifications
              }
            , Cmd.batch [ getWallet (), getGlobalConfig () ]
            )

        MonsterCreationFailed err ->
            handleMonsterAction model err "Create" False

        RequestMonsterTransfer petId -> 
           ( { model 
               | showMonsterTransfer = True 
               , petIdForTransfer = petId
           }, Cmd.none ) 

        MonsterTransferSucceed trxId -> 
            handleMonsterAction model trxId "Transfer" True

        MonsterTransferFailed err -> 
            handleMonsterAction model err "Transfer" True  

        RequestMonsterClaim petId -> 
           ( { model | isLoading = True }, requestClaim (petId) ) 

        MonsterClaimSucceed trxId -> 
            handleMonsterAction model trxId "Claim" True
        MonsterClaimFailed err -> 
            handleMonsterAction model err "Claim" True  

        ScatterSignIn userJson ->
            case (JD.decodeValue userDecoder userJson) of
                Ok user ->
                    ( { model
                        | user = user
                        , content = MyMonsters
                        , notifications = [ Notification (Success ("Welcome " ++ user.eosAccount)) model.currentTime "signInSuccess" ] ++ model.notifications
                      }
                    , Cmd.batch [ getWallet (), getGlobalConfig () ]
                    )

                Err err ->
                    ( { model
                        | notifications = [ Notification (Error ("Fail to SignIn: " ++ err)) model.currentTime "signInFailed" ] ++ model.notifications
                        , isLoading = False
                      }
                    , Cmd.none
                    )

        SetWallet rawWallet ->
            case (JD.decodeValue walletDecoder rawWallet) of
                Ok wallet ->
                    ( { model | wallet = wallet, isLoading = False }
                    , Cmd.none
                    )

                Err err ->
                    ( { model
                        | notifications = [ Notification (Error ("Fail to Parse Wallet Funds: " ++ err)) model.currentTime "parseWalletFailed" ] ++ model.notifications
                        , isLoading = False
                      }
                    , Cmd.none
                    )

        SetWalletFailure err ->
            ( { model
                | isLoading = False
                , notifications = [ Notification (Error ("Fail to load Wallet: " ++ err)) model.currentTime (toString model.currentTime) ] ++ model.notifications
              }
            , Cmd.none
            )

        SetGlobalConfig rawGlobalConfig ->
            case (JD.decodeValue globalConfigDecoder rawGlobalConfig) of
                Ok globalConfig ->
                    ( { model | globalConfig = globalConfig }
                    , listMonsters ()
                    )

                Err err ->
                    ( { model
                        | notifications = [ Notification (Error ("Fail to Parse GlobalConfig: " ++ err)) model.currentTime "parseGlobalConfigFailed" ] ++ model.notifications
                        , isLoading = False
                      }
                    , Cmd.none
                    )

        SetGlobalConfigFailure err ->
            ( { model
                | isLoading = False
                , notifications = [ Notification (Error ("Fail to load Global Config: " ++ err)) model.currentTime (toString model.currentTime) ] ++ model.notifications
              }
            , Cmd.none
            )

        SetMonsters monsterList ->
            case (JD.decodeValue monstersDecoder monsterList) of
                Ok monsters ->
                    ( { model | monsters = monsters, isLoading = False }, Cmd.none )

                Err err ->
                    ( { model
                        | notifications = [ Notification (Error ("Fail to Parse Monsters: " ++ err)) model.currentTime "parseMonstersFailed" ] ++ model.notifications
                        , isLoading = False
                      }
                    , Cmd.none
                    )

        SetMonstersFailure err ->
            ( { model
                | isLoading = False
                , notifications = [ Notification (Error ("Fail to load Monsters List: " ++ err)) model.currentTime (toString model.currentTime) ] ++ model.notifications
              }
            , Cmd.none
            )

        RefreshPage ->
            ( model, refreshPage () )

        Tick time ->
            let
                -- erase after 10 secs
                notifications =
                    model.notifications
                        |> List.filter
                            (\notification ->
                                (model.currentTime - notification.time) < 10000
                            )
            in
                ( { model | currentTime = time, notifications = notifications }, Cmd.none )

        DeleteNotification id ->
            let
                notifications =
                    model.notifications
                        |> List.filter (\notification -> notification.id /= id)
            in
                ( { model | notifications = notifications }, Cmd.none )

        SetContent content ->
            ( { model | content = content }, Cmd.none )

        UpdateNewMonsterName name ->
            ( { model | newMonsterName = name }, Cmd.none )

        SubmitNewMonster ->
            ( { model | isLoading = True }, submitNewMonster (model.newMonsterName) )

        UpdateNewOwnerAccount newOwner -> 
            ( { model | newOwnerAccount = newOwner}, Cmd.none)

        SubmitTransferMonster -> 
        ({model | isLoading = True}, submitNewOwner(model.petIdForTransfer, model.newOwnerAccount) )

        UpdateDepositAmount txtAmount ->
            ( { model
                | depositAmount =
                    (Result.withDefault model.depositAmount
                        (String.toFloat txtAmount)
                    )
              }
            , Cmd.none
            )

        UpdateCurrentRankPage txtPage ->
            ( { model
                | currentRankPage =
                    (Result.withDefault model.currentRankPage
                        (String.toInt txtPage)
                    )
              }
            , Cmd.none
            )

        SubmitDeposit ->
            ( { model | isLoading = True }, requestDeposit (model.depositAmount) )

        ToggleHelp ->
            ( { model | showHelp = (not model.showHelp) }, Cmd.none )

        ToggleWallet ->
            ( { model | showWallet = (not model.showWallet), depositAmount = 3 }
            , Cmd.none
            )

        ToggleMonsterCreation ->
            ( { model
                | newMonsterName = ""
                , showMonsterCreation = (not model.showMonsterCreation)
              }
            , Cmd.none
            )
        
        ToggleMonsterTransfer -> 
            ( { model
                | newOwnerAccount = ""
                , showMonsterTransfer = (not model.showMonsterTransfer)
              }
            , Cmd.none
            )

        Logout ->
            ( initialModel, signOut () )


handleMonsterRequest : Model -> MonsterRequest -> Int -> Maybe Notification
handleMonsterRequest model requestType petId =
    let
        monster =
            model.monsters |> List.filter (\m -> m.id == petId) |> List.head

        currentTime =
            model.currentTime

        warnNotification msg req =
            Notification (Warning msg) currentTime req
    in
        case monster of
            Just monster ->
                if requestType == Feed && (currentTime - monster.last_fed_at) < monsterMinFeedInterval then
                    Just (warnNotification "I'm Not hungry..." "notHungryWarning")
                else if requestType == Sleep && (currentTime - monster.last_awake_at) < monsterMinAwakeInterval then
                    Just (warnNotification "I don't want to Sleep!!!" "notSleepyWarning")
                else if requestType == Awake && (currentTime - monster.last_bed_at) < monsterMinSleepPeriod then
                    Just (warnNotification "Zzzzz... leave me alone!" "notAwaking")
                else
                    Nothing

            Nothing ->
                Just (warnNotification "Invalid Monster" "invalidMonster")


handleMonsterAction : Model -> String -> String -> Bool -> ( Model, Cmd Msg )
handleMonsterAction model msg action isSuccess =
    let
        time =
            model.currentTime

        timeTxt =
            toString time

        ( notification, cmd ) =
            if isSuccess then
                ( Notification (Success ("Monster attempt to " ++ action ++ " ! TrxId: " ++ msg)) time timeTxt, listMonsters () )
            else
                ( Notification (Error ("Fail to " ++ action ++ " Monster: " ++ msg)) time timeTxt, Cmd.none )
    in
        ( { model
            | isLoading = False
            , notifications = [ notification ] ++ model.notifications
          }
        , cmd
        )


handleActionResponse : Model -> String -> String -> Bool -> ( Model, Cmd Msg )
handleActionResponse model msg action isSuccess =
    let
        time =
            model.currentTime

        timeTxt =
            toString time

        ( notification, cmd ) =
            if isSuccess then
                ( Notification (Success ("Action attempt to " ++ action ++ " ! TrxId: " ++ msg)) time timeTxt
                , Cmd.batch [ getWallet (), getGlobalConfig () ]
                )
            else
                ( Notification (Error ("Fail to execute " ++ action ++ " action: " ++ msg)) time timeTxt, Cmd.none )
    in
        ( { model
            | isLoading = False
            , notifications = [ notification ] ++ model.notifications
          }
        , cmd
        )


handleResponseErrors : Model -> Http.Error -> String -> ( Model, Cmd Msg )
handleResponseErrors model err msg =
    let
        _ =
            Debug.log msg err

        error =
            case err of
                Http.BadStatus res ->
                    (toString res.status.code) ++ " - " ++ (toString res.body)

                Http.BadPayload msg _ ->
                    msg

                _ ->
                    "Http/Network Fail"
    in
        ( { model | error = Just error, isLoading = False }, Cmd.none )


userDecoder : JD.Decoder User
userDecoder =
    JD.map2
        User
        (JD.field "eosAccount" JD.string)
        (JD.field "publicKey" JD.string)


globalConfigDecoder : JD.Decoder GlobalConfig
globalConfigDecoder =
    JDP.decode GlobalConfig
        |> JDP.required "last_id" JD.int
        |> JDP.required "creation_fee" JD.string
        |> JDP.required "max_health" JD.int
        |> JDP.required "hunger_to_zero" JD.int
        |> JDP.required "min_hunger_interval" JD.int
        |> JDP.required "max_hunger_points" JD.int
        |> JDP.required "hunger_hp_modifier" JD.int
        |> JDP.required "min_awake_interval" JD.int
        |> JDP.required "min_sleep_period" JD.int
        |> JDP.required "creation_tolerance" JD.int
        |> JDP.required "monsters_to_activate_fee" JD.int


walletDecoder : JD.Decoder Wallet
walletDecoder =
    JDP.decode Wallet
        |> JDP.required "funds" JD.float


monstersDecoder : JD.Decoder (List Monster)
monstersDecoder =
    JD.list
        (JDP.decode Monster
            |> JDP.required "id" JD.int
            |> JDP.required "owner" JD.string
            |> JDP.required "new_owner" JD.string
            |> JDP.required "name" JD.string
            |> JDP.required "type" JD.int
            |> JDP.required "created_at" JD.float
            |> JDP.required "death_at" JD.float
            |> JDP.required "health" JD.int
            |> JDP.required "hunger" JD.int
            |> JDP.required "last_fed_at" JD.float
            |> JDP.required "awake" JD.int
            |> JDP.required "is_sleeping" JD.bool
            |> JDP.required "last_bed_at" JD.float
            |> JDP.required "last_awake_at" JD.float
            |> JDP.required "happiness" JD.int
            |> JDP.required "last_play_at" JD.float
            |> JDP.required "clean" JD.int
            |> JDP.required "last_shower_at" JD.float
        )


calcTimeDiff : Time.Time -> Time.Time -> String
calcTimeDiff timeOld timeNew =
    let
        defaultConfig =
            Distance.defaultConfig

        config =
            { defaultConfig | includeSeconds = True }

        inWords =
            config
                |> Distance.inWordsWithConfig
    in
        inWords (Date.fromTime timeOld) (Date.fromTime timeNew)


formatTime : Time.Time -> String
formatTime time =
    if time > 0 then
        time
            |> Date.fromTime
            |> DateFormat.format DateConfig.config
                "%B, %e %Y @ %H:%M:%S %P"
    else
        ""


reversedComparison : comparable -> comparable -> Order
reversedComparison a b =
    case compare a b of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT



-- reusable components


icon : String -> Bool -> Bool -> Html Msg
icon icon spin isLeft =
    let
        spinner =
            if spin then
                " fa-spin"
            else
                ""

        className =
            "fa" ++ spinner ++ " fa-" ++ icon

        classIcon =
            if isLeft then
                "icon is-left"
            else
                "icon"
    in
        span [ class classIcon ]
            [ i [ class className ]
                []
            ]


loadingIcon : Model -> Html Msg
loadingIcon model =
    if model.isLoading then
        icon "spinner" True False
    else
        text ""


disabledAttribute : Bool -> Attribute msg
disabledAttribute isDisabled =
    if isDisabled then
        attribute "disabled" "true"
    else
        attribute "data-empty" ""


fieldInput : Model -> String -> String -> String -> String -> (String -> Msg) -> Html Msg
fieldInput model fieldLabel fieldValue fieldPlaceHolder fieldIcon fieldMsg =
    let
        loadingClass =
            if model.isLoading then
                " is-loading"
            else
                ""
    in
        div [ class "field" ]
            [ label [ class "label is-large" ]
                [ text fieldLabel ]
            , div
                [ class
                    ("control has-icons-left has-icons-right"
                        ++ loadingClass
                    )
                ]
                [ input
                    [ class "input is-large"
                    , placeholder fieldPlaceHolder
                    , type_ "text"
                    , defaultValue fieldValue
                    , onInput fieldMsg
                    ]
                    []
                , icon fieldIcon False True
                ]
            ]


selectInput : Bool -> List ( String, String ) -> String -> String -> String -> (String -> Msg) -> Html Msg
selectInput isLoading optionsType fieldLabel fieldValue fieldIcon fieldMsg =
    let
        options =
            optionsType
                |> List.map
                    (\( optVal, optText ) ->
                        let
                            selectedAttr =
                                if optVal == fieldValue then
                                    [ value optVal
                                    , attribute "selected" ""
                                    ]
                                else
                                    [ value optVal ]
                        in
                            option
                                selectedAttr
                                [ text optText ]
                     -- option [ value optVal ] [ text optText ]
                    )

        loadingClass =
            if isLoading then
                " is-loading"
            else
                ""
    in
        div [ class "field" ]
            [ label [ class "label is-large" ]
                [ text fieldLabel ]
            , div [ class ("control has-icons-left" ++ loadingClass) ]
                [ div [ class "select is-large is-fullwidth" ]
                    [ select [ onInput fieldMsg, disabledAttribute isLoading ] options ]
                , icon fieldIcon False True
                ]
            ]


titleMenu : String -> List (Html msg) -> Html msg
titleMenu title menu =
    div [ class "level" ]
        [ div [ class "level-left" ]
            [ div [ class "level-item" ] [ h1 [ class "title" ] [ text title ] ] ]
        , div [ class "level-right" ]
            (menu
                |> List.map (\item -> div [ class "level-item" ] [ item ])
            )
        ]


modalCard : Model -> String -> Msg -> List (Html Msg) -> Maybe ( String, Msg ) -> Maybe ( String, Msg ) -> Html Msg
modalCard model title close body ok cancel =
    let
        loadingClass =
            if model.isLoading then
                " is-loading"
            else
                ""

        okButton =
            case ok of
                Just ( txt, msg ) ->
                    button
                        [ class ("button is-success" ++ loadingClass)
                        , onClick msg
                        , disabledAttribute model.isLoading
                        ]
                        [ text txt ]

                Nothing ->
                    text ""

        cancelButton =
            case cancel of
                Just ( txt, msg ) ->
                    button
                        [ class ("button is-light" ++ loadingClass)
                        , onClick msg
                        , disabledAttribute model.isLoading
                        ]
                        [ text txt ]

                Nothing ->
                    text ""
    in
        div [ class "modal is-active" ]
            [ div [ class "modal-background" ] []
            , div [ class "modal-card" ]
                [ header [ class "modal-card-head" ]
                    [ p [ class "modal-card-title" ]
                        [ loadingIcon model, text title ]
                    , button
                        [ class "delete"
                        , attribute "aria-label" "close"
                        , onClick close
                        ]
                        []
                    ]
                , section [ class "modal-card-body" ]
                    body
                , footer [ class "modal-card-foot" ]
                    [ okButton
                    , cancelButton
                    ]
                ]
            ]



-- view


notification : Notification -> Html Msg
notification notification =
    let
        ( txt, messageClass ) =
            case notification.notification of
                Success txt ->
                    ( txt, "is-success" )

                Warning txt ->
                    ( txt, "is-warning" )

                Error txt ->
                    ( txt, "is-danger" )
    in
        div [ class ("notification on " ++ messageClass) ]
            [ button
                [ class "delete"
                , onClick (DeleteNotification notification.id)
                ]
                []
            , text txt
            ]


notificationsView : Model -> Html Msg
notificationsView model =
    div [ class "toast" ] (model.notifications |> List.map notification)


monsterCreationModal : Model -> Html Msg
monsterCreationModal model =
    let
        modalClass =
            if model.showHelp then
                "modal is-active"
            else
                "modal"

        scatterInstalled =
            model.scatterInstalled
    in
        modalCard model
            "Create a New Monster"
            ToggleMonsterCreation
            [ form []
                [ fieldInput
                    model
                    "New Monster Name"
                    model.newMonsterName
                    "Pikachu"
                    "paw"
                    UpdateNewMonsterName
                ]
            ]
            (Just ( "Submit", SubmitNewMonster ))
            (Just ( "Cancel", ToggleMonsterCreation ))


walletModal : Model -> Html Msg
walletModal model =
    let
        modalClass =
            if model.showHelp then
                "modal is-active"
            else
                "modal"

        scatterInstalled =
            model.scatterInstalled

        initialDeposit =
            String.split " " model.globalConfig.creationFee
                |> List.head

        initialDepositText =
            case initialDeposit of
                Just val ->
                    val

                Nothing ->
                    "1"
    in
        modalCard model
            "Deposit EOS in Wallet"
            ToggleWallet
            [ form []
                [ p []
                    [ text ("You have " ++ (toString model.wallet.funds) ++ " EOS available in your MonsterEOS Wallet.")
                    , br [] []
                    , text (" Each monster has a creation fee of " ++ model.globalConfig.creationFee ++ ".")
                    ]
                , div [ class "has-margin-top" ]
                    [ fieldInput
                        model
                        "Deposit EOS Amount"
                        initialDepositText
                        initialDepositText
                        "suitcase"
                        UpdateDepositAmount
                    ]
                , p [ class "has-text-danger has-margin-top" ]
                    [ text "The EOS deposited in MonsterEOS wallet will be used to buy future items, monsters add-ons and any other cool feature that we will probably implement. Initially we thought about charging a Monster Creation Fee, but people has been very generous with donations so we are planning to just leave the Monster creation free and everyone will be able to have a pet for free!" ]
                , p [ class "has-text-info har-margin-top" ]
                    [ text "All of this will be used to buy coffee for MonsterEOS Contributors <3 Remember it's also an educational project, open sourced, for the whole community, so please show your love to us!" ]
                ]
            ]
            (Just ( "Add Funds", SubmitDeposit ))
            (Just ( "Cancel", ToggleWallet ))

monsterTransferModal : Model -> Html Msg
monsterTransferModal model =
    let
        modalClass =
            if model.showHelp then
                "modal is-active"
            else
                "modal"

        scatterInstalled =
            model.scatterInstalled
    in
        modalCard model
            "Transfer Monster "
            ToggleMonsterTransfer
            [ form []
                [ fieldInput
                    model
                    "New owner"
                    model.newOwnerAccount
                    "monstereosio"
                    "user"
                    UpdateNewOwnerAccount
                ]
            ]
            (Just ( "Submit", SubmitTransferMonster ))
            (Just ( "Cancel", ToggleMonsterTransfer ))


helpModal : Model -> Html Msg
helpModal model =
    let
        modalClass =
            if model.showHelp then
                "modal is-active"
            else
                "modal"

        scatterInstalled =
            model.scatterInstalled
    in
        modalCard model
            "Help"
            ToggleHelp
            [ div [ class "content" ]
                [ strong [] [ text "Please check our About page to understand the project and to read the Disclaimer. By creating a Monster you are agreeing with it!" ]
                , p []
                    [ text "Just install Scatter and you will be able to create your first monster on EOS MainNet!" ]
                , h2 [ class "title" ] [ text "Quick FAQ" ]
                , p []
                    [ strong [] [ text "I created my monster, it's sleeping and I can't interact with, what should I do?" ]
                    , br [] []
                    , text "It's the spawning time, every time your pet is sleeping it needs a minimum period of 4 hours to rest and be awake again."
                    ]
                , p []
                    [ strong [] [ text "Why my pet does not want to eat?" ]
                    , br [] []
                    , text "Your pet is full, it needs at least an interval of 3 hours before you feed him again."
                    ]
                , p []
                    [ strong [] [ text "Why my pet does not want to sleep?" ]
                    , br [] []
                    , text "Your pet is not tired, it needs to be at least 8 hours awake to go sleep again!"
                    ]
                ]
            ]
            Nothing
            Nothing


topMenu : Model -> Html Msg
topMenu model =
    let
        loggedOut =
            String.isEmpty model.user.eosAccount

        aboutActiveClass =
            if model.content == About then
                " is-active"
            else
                ""

        helpButton =
            a
                [ class "navbar-item help-button"
                , onClick ToggleHelp
                ]
                [ span [ class "navbar-item icon is-small" ]
                    [ i [ class "fa fa-2x fa-question-circle has-text-info" ] [] ]
                ]

        aboutButton =
            a
                [ class ("navbar-item" ++ aboutActiveClass)
                , onClick (SetContent About)
                , href "javascript:;"
                ]
                [ text "About"
                ]

        content =
            if loggedOut then
                let
                    scatterButton =
                        if model.scatterInstallPressed then
                            a [ class "navbar-item", onClick RefreshPage ]
                                [ text "Refresh page after Scatter Installation" ]
                        else if model.scatterInstalled then
                            a
                                [ class "navbar-item"
                                , onClick ScatterRequestIdentity
                                , href "javascript:;"
                                ]
                                [ text "Enter with Scatter" ]
                        else
                            a
                                [ class "navbar-item"
                                , onClick ScatterInstallPressed
                                , href scatterExtensionLink
                                , target "_blank"
                                ]
                                [ text "Install Scatter Wallet" ]
                in
                    [ p [ class "navbar-item" ] [ loadingIcon model ]
                    , a
                        [ class "navbar-item"
                        , onClick (SetContent Home)
                        , href "javascript:;"
                        ]
                        [ text "Home"
                        ]
                    , scatterButton
                    , aboutButton
                    , helpButton
                    ]
            else
                let
                    soundIcon =
                        "fa fa-2x "
                            ++ if model.isMuted then
                                "fa-volume-off has-text-danger"
                               else
                                "fa-volume-up has-text-success"

                    monstersActiveClass =
                        if model.content == MyMonsters then
                            " is-active"
                        else
                            ""

                    rankActiveClass =
                        if model.content == Rank then
                            " is-active"
                        else
                            ""
                in
                    [ p [ class "navbar-item greetings" ]
                        [ loadingIcon model
                        , text "Hello"
                        , span [] [ b [] [ text model.user.eosAccount ] ]
                        , text "!"
                        ]
                    , div [ class "navbar-item" ]
                        [ div [ class "field is-grouped" ]
                            [ p [ class "control" ]
                                [ a
                                    [ class "button is-primary"
                                    , onClick ToggleWallet
                                    , href "javascript:;"
                                    ]
                                    [ span [ class "icon" ] [ icon "suitcase" False False ]
                                    , span [] [ text (toString model.wallet.funds ++ " EOS") ]
                                    ]
                                ]
                            ]
                        ]
                    , a
                        [ class ("navbar-item" ++ monstersActiveClass)
                        , onClick (SetContent MyMonsters)
                        , href "javascript:;"
                        ]
                        [ icon "paw" False False
                        , text "My Monsters"
                        ]
                    , a
                        [ class ("navbar-item" ++ rankActiveClass)
                        , onClick (SetContent Rank)
                        , href "javascript:;"
                        ]
                        [ icon "trophy" False False
                        , text "Rank"
                        ]
                    , aboutButton
                    , a
                        [ class "navbar-item"
                        , onClick Logout
                        , href "javascript:;"
                        ]
                        [ icon "sign-out" False False
                        , text "Logout"
                        ]
                    , helpButton
                    ]
    in
        nav
            [ attribute "aria-label" "main navigation"
            , class "navbar"
            , attribute "role" "navigation"
            ]
            [ div [ class "navbar-brand logo" ]
                [ text "MonsterEOS" ]
            , div [ class "navbar-menu" ]
                [ div [ class "navbar-end" ]
                    content
                ]
            ]


mainContent : Model -> Html Msg
mainContent model =
    let
        defaultContent content =
            section [ class "section" ]
                [ div [ class "container" ]
                    [ content
                    ]
                ]

        mainContent =
            case model.content of
                Home ->
                    if model.isLoading then
                        section [ class "is-large" ]
                            [ loadingIcon model ]
                    else
                        section [ class "hero is-info is-medium" ]
                            [ div [ class "hero-body" ]
                                [ div [ class "container" ]
                                    [ div
                                        [ class "columns" ]
                                        [ div [ class "column" ]
                                            [ figure [ class "image" ]
                                                [ img [ alt "Tamagotchi Monsters", src "images/monsters/monster-105.png" ]
                                                    []
                                                ]
                                            ]
                                        , div [ class "column" ]
                                            [ h1 [ class "title logo" ]
                                                [ text "I'm a Monster Tamagotchi alike game for EOS blockchain! :)" ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]

                MyMonsters ->
                    defaultContent (monsterContent model)

                Rank ->
                    defaultContent (rankContent model)

                About ->
                    defaultContent (aboutContent model)
    in
        mainContent


aboutContent : Model -> Html Msg
aboutContent model =
    div [ class "content" ]
        [ h1 [ class "title" ] [ text "About" ]
        , p [] [ b [] [ text "It's Just a Tamagotchi Game to show off EOS blockchain potential! You as an early adopter, will have a chance to carry a very old Monster while the game is in progress, getting cool functionalities and public traction :D" ] ]
        , p [] [ text "This project is a mini-game experiment for EOS Blockchain, still in progress. It's open sourced and all of us can tweak the contract, architecture and design of tables to see what works the best in terms of performance and good practices for EOS." ]
        , p [] [ text "To keep your pet alive you must feed him, play with him, take him to the bed and wash him!" ]
        , p [] [ text "Only the feeding and sleeping/awake feature is done for now... There's a lot of interesting stuff that we can do here to improve the project like experience points (+ age and evolutions), inventory of items, multiplayer options, breeding, ownership transferring and tokenization." ]
        , p [] [ text "We would love to have more and more developers to get in touch in GitHub repository, open issues, open discussions and so on, about what would be the best way to design the architecture and implement the contracts, how things should work in blockchain, how we should integrate Scatter, other wallets and provide top-security, what we should avoid, what's the best practice in terms of coding and everything else." ]
        , p [] [ text "We love EOS Community and we think that we can build a better world together!" ]
        , p [] [ text "Monsters Pictures Package: ", a [ href "https://pipoya.itch.io/free-rpg-monster-pack", target "_blank" ] [ text "Itch.io @Pipoya - Free RPG Monster Pack" ] ]
        , p [] [ text "Sleeping GIF Credits: ", a [ href "https://giphy.com/stickers/zzz-snore-51WvIEoUKKHlGwgmgy", target "_blank" ] [ text "Giphy @AlabasterPizzo" ] ]
        , b [] [ text "Disclaimer" ]
        , p [] [ text "This project remains purely experimental software and is not to be considered in any way production fit nor has any guarantee of any kind. Use at your own risk." ]
        , p [] [ text "Any transferred tokens sent to account name 'monstereosio' will not return any entitlement of any asset, investment digital or physical including the sent asset itself. Any proceeds received from any user transfers are of the sole control and discretion of the receiver." ]
        ]


monsterCard : Monster -> Time.Time -> Bool -> Bool -> Bool -> Html Msg
monsterCard monster currentTime isLoading readOnly canBeClaimed =
    let
        isDead =
            monster.death_at > 0 || monster.health <= 0

        deathTimeTxt =
            formatTime monster.death_at

        birthDateTxt =
            formatTime monster.created_at

        ( sleepingClass, sleepingGif ) =
            if monster.is_sleeping && not isDead then
                ( " sleeping", img [ src "images/zzz.gif" ] [] )
            else
                ( "", text "" )

        ( deadClass, deadImgClass, deathInfo, aliveInfo, interactionFooter ) =
            if isDead then
                ( " has-text-danger"
                , " grayscale"
                , span [ class "is-6 has-text-danger" ]
                    [ br [] []
                    , text "DEAD IN "
                    , time [ datetime deathTimeTxt ]
                        [ text deathTimeTxt ]
                    ]
                , span [ class "is-6 has-text-danger" ]
                    [ text ("Stayed alive for " ++ (calcTimeDiff monster.created_at monster.death_at)) ]
                , footer [ class "card-footer" ]
                    [ div [ class "card-footer-item has-text-centered" ]
                        [ a [ class "is-danger", onClick (RequestMonsterDelete monster.id) ]
                            [ text "Delete Monster" ]
                        ]
                    ]
                )
            else
                ( ""
                , ""
                , text ""
                , p [ class "is-6 has-text-success" ]
                    [ text ("Is alive for " ++ (calcTimeDiff monster.created_at currentTime)) ]
                , footer [ class "card-footer" ]
                    (if monster.is_sleeping then
                        [ a
                            [ class "card-footer-item"
                            , onClick (RequestMonsterAwake monster.id)
                            , disabledAttribute isLoading
                            ]
                            [ text "Wake Up!" ]
                        ]
                    else if canBeClaimed then 
                        [ a
                            [ class "card-footer-item"
                            , onClick (RequestMonsterClaim monster.id)
                            , disabledAttribute isLoading
                            ]
                            [ text "Claim" ]
                        ]
                    else 
                        [ a
                            [ class "card-footer-item"
                            , onClick (RequestMonsterFeed monster.id)
                            , disabledAttribute isLoading
                            ]
                            [ text "Feed" ]
                        , a
                            [ class "card-footer-item"
                            , onClick (RequestMonsterPlay monster.id)
                            , disabledAttribute isLoading
                            ]
                            [ text "Play" ]
                        , a
                            [ class "card-footer-item"
                            , onClick (RequestMonsterWash monster.id)
                            , disabledAttribute isLoading
                            ]
                            [ text "Wash" ]
                        , a
                            [ class "card-footer-item"
                            , onClick (RequestMonsterBed monster.id)
                            , disabledAttribute isLoading
                            ]
                            [ text "Bed Time!" ]
                        , a
                            [ class "card-footer-item"
                            , onClick (RequestMonsterTransfer monster.id)
                            , disabledAttribute isLoading
                            ]
                            [ text "Transfer" ]
                        ] 
                    )
                )
    in
        div [ class "column monster-column" ]
            [ div [ class "card" ]
                [ div [ class "card-content" ] [ p [ class ("title is-4 " ++ deadClass) ] [ text monster.name ] ]
                , div [ class "card-image" ]
                    [ figure [ class ("image monster-image is-square" ++ deadImgClass) ]
                        [ img [ alt monster.name, class sleepingClass, src ("images/monsters/monster-" ++ (toString monster.mtype) ++ ".png") ]
                            []
                        , sleepingGif
                        ]
                    ]
                , div
                    [ class "card-content" ]
                    [ div [ class "content" ]
                        [ p []
                            [ span [ class "is-6" ]
                                [ b [] [ text "Owner: " ], text monster.owner ]
                            , span [ class ("is-pulled-right " ++ deadClass) ]
                                [ text ("#" ++ toString monster.id) ]
                            ]
                        , div [ class "is-6" ]
                            [ p []
                                [ text "Birth Date: "
                                , time [ datetime birthDateTxt ]
                                    [ text birthDateTxt ]
                                , br [] []
                                , aliveInfo
                                , deathInfo
                                ]
                            ]
                        , p [ class "is-large has-margin-top" ]
                            [ b [] [ text "HP: " ]
                            , progress [ class "progress is-danger", Html.Attributes.max "100", value (toString monster.health) ]
                                [ text (toString monster.health) ]
                            ]
                        , div [ class "columns is-multiline" ]
                            [ div [ class "column is-half" ]
                                [ b [] [ text "Food: " ]
                                , progress [ class "progress is-primary", Html.Attributes.max "100", value (toString monster.hunger) ]
                                    [ text (toString monster.hunger) ]
                                ]
                            , div [ class "column is-half" ]
                                [ b [] [ text "Happiness: " ]
                                , progress [ class "progress is-warning", Html.Attributes.max "100", value (toString monster.happiness) ]
                                    [ text (toString monster.happiness) ]
                                ]
                            , div [ class "column is-half" ]
                                [ b [] [ text "Energy: " ]
                                , progress [ class "progress is-success", Html.Attributes.max "100", value (toString monster.awake) ]
                                    [ text (toString monster.awake) ]
                                ]
                            , div [ class "column is-half" ]
                                [ b [] [ text "Clean: " ]
                                , progress [ class "progress is-info", Html.Attributes.max "100", value (toString monster.clean) ]
                                    [ text (toString monster.clean) ]
                                ]
                            ]
                        ]
                    ]
                , (if readOnly then
                    text ""
                   else
                    interactionFooter
                  )
                ]
            ]


monsterContent : Model -> Html Msg
monsterContent model =
    let
        myMonsters =
            (model.monsters
                |> List.filter (\monster -> monster.owner == model.user.eosAccount || monster.new_owner == model.user.eosAccount)
                |> List.map (\monster -> monsterCard monster model.currentTime model.isLoading False (monster.new_owner == model.user.eosAccount))
            )

        newMonsterMsg =
            if List.length myMonsters < 1 then
                "Looks like you don't have any Monster yet... What about create a new monster on the above button?!"
            else
                ""
    in
        div []
            [ div [ class "content" ]
                [ titleMenu "My Monsters"
                    [ a
                        [ class "button is-success new-monster-button"
                        , onClick ToggleMonsterCreation
                        , disabledAttribute model.isLoading
                        ]
                        [ text "New Monster" ]
                    ]
                , p [] [ text newMonsterMsg ]
                ]
            , div [ class "columns is-multiline" ]
                myMonsters
            ]


rankContent : Model -> Html Msg
rankContent model =
    let
        monsters =
            (model.monsters
                |> List.filter (\monster -> monster.death_at == 0)
                |> List.sortBy .created_at
            )

        monstersSize =
            List.length monsters

        currentPage =
            toString model.currentRankPage

        pageSize =
            30

        pages =
            ceiling (toFloat (monstersSize) / pageSize)

        pagesOptions =
            List.range 0 (pages - 1)
                |> List.map
                    (\r ->
                        ( toString r
                        , ("Page "
                            ++ toString (r + 1)
                            ++ ": From "
                            ++ toString (r * pageSize + 1)
                            ++ " to "
                            ++ toString (pageSize + (r * pageSize))
                          )
                        )
                    )

        pagination =
            selectInput model.isLoading pagesOptions "" currentPage "trophy" UpdateCurrentRankPage

        paginatedMonsters =
            monsters
                |> List.drop (pageSize * model.currentRankPage)
                |> List.take pageSize
                |> List.map (\monster -> monsterCard monster model.currentTime model.isLoading True False)
    in
        div []
            [ titleMenu "Eldest Alive Monsters" [ pagination ]
            , div [ class "columns is-multiline" ]
                paginatedMonsters
            , titleMenu "" [ pagination ]
            ]


pageFooter : Html Msg
pageFooter =
    footer [ class "footer" ]
        [ div [ class "container" ]
            [ div [ class "content has-text-centered" ]
                [ p []
                    [ strong []
                        [ text "MonsterEOS" ]
                    , text " "
                    , a [ href "https://github.com/leordev/monstereos" ]
                        [ text "GitHub" ]
                    , text " - The source code is licensed "
                    , a [ href "http://opensource.org/licenses/mit-license.php" ]
                        [ text "MIT" ]
                    , text "."
                    , a [ href "https://t.me/joinchat/Hel9rgyuHrEwzsjG2SlUNQ" ]
                        [ text "Telegram" ]
                    ]
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    let
        modal =
            if model.showHelp then
                helpModal model
            else if model.showWallet then
                walletModal model
            else if model.showMonsterCreation then
                monsterCreationModal model
            else
                text ""
    in
        div []
            [ topMenu model
            , notificationsView model
            , mainContent model
            , pageFooter
            , modal
            ]
