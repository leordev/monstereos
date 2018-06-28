port module Main exposing (..)

import Date.Distance as Distance
import Date
import Html exposing (..)
import Html.Attributes exposing (attribute, class, defaultValue, href, placeholder, target, type_, value, datetime, alt, src, max, style, id)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as JD
import Time
import Json.Decode.Pipeline as JDP
import Date.Extra.Format as DateFormat
import Date.Extra.Config.Config_en_us as DateConfig
import Json.Encode as JE


-- import FormatNumber
-- import FormatNumber.Locales exposing (usLocale)


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            initModel flags

        cmds =
            Cmd.batch [ listPetTypes (), listElements () ]

        cmd =
            if not (String.isEmpty model.user.eosAccount) then
                ( { model | isLoading = True }
                , cmds
                )
            else
                ( model, cmds )
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
    , battlesInitialized = False
    , battles = []
    , elements = []
    , petTypes = []
    , battleSelectedMonster = 0
    , battleSelectedAttackElement = 0
    , battleSelectedAttackMonster = 0
    , battleSelectedAttackEnemy = 0
    , currentBattle = Nothing
    , battleLog = []
    , battleNotifications = []
    , battleWinner = Nothing
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
    | ViewBattle Battle
    | MyMonsters
    | Rank
    | BattleArena
    | About


type BattlePhase
    = BattleJoiningPhase
    | BattleStartingPhase
    | BattlePickingPhase
    | BattleOnGoingPhase
    | BattleFinishedPhase
    | BattleUnknownPhase


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
    , maxArenas : Int
    , battleIdleTolerance : Int
    }


type alias Element =
    { id : Int
    , name : String
    , ratios : List Int
    }


type alias PetType =
    { id : Int
    , elements : List Int
    }


type alias BattlePetStat =
    { petId : Int
    , petType : Int
    , player : String
    , hp : Int
    }


type alias BattleCommit =
    { player : String
    , commitment : String
    , reveal : String
    }


type alias Battle =
    { host : String
    , mode : Int
    , startedAt : Time.Time
    , lastMoveAt : Time.Time
    , turns : List BattleCommit
    , petsStats : List BattlePetStat
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
    , maxArenas = 0
    , battleIdleTolerance = 0
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


type alias BattleLog =
    { time : Time.Time
    , battle : Battle
    }


type BattleNotificationType
    = HealthPoints


type alias BattleNotification =
    { time : Time.Time
    , petId : Int
    , nType : BattleNotificationType
    , hp : Int
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
    , battlesInitialized : Bool
    , battles : List Battle
    , elements : List Element
    , petTypes : List PetType
    , battleSelectedMonster : Int
    , battleSelectedAttackMonster : Int
    , battleSelectedAttackElement : Int
    , battleSelectedAttackEnemy : Int
    , currentBattle : Maybe Battle
    , battleLog : List BattleLog
    , battleNotifications : List BattleNotification
    , battleWinner : Maybe String
    }



-- Helper Constants


battlePlayersQty : Int
battlePlayersQty =
    2


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


availableArenas : Int
availableArenas =
    18


hpNotificationSeconds : Time.Time
hpNotificationSeconds =
    3000



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



-- battle interface


port listBattles : () -> Cmd msg


port listBattlesSucceed : (JD.Value -> msg) -> Sub msg


port listBattlesFailed : (String -> msg) -> Sub msg


port listElements : () -> Cmd msg


port listElementsSucceed : (JD.Value -> msg) -> Sub msg


port listElementsFailed : (String -> msg) -> Sub msg


port listPetTypes : () -> Cmd msg


port listPetTypesSucceed : (JD.Value -> msg) -> Sub msg


port listPetTypesFailed : (String -> msg) -> Sub msg


port battleCreate : Int -> Cmd msg


port battleCreateSucceed : (String -> msg) -> Sub msg


port battleCreateFailed : (String -> msg) -> Sub msg


port showChat : String -> Cmd msg


port battleJoin : String -> Cmd msg


port battleJoinSucceed : (String -> msg) -> Sub msg


port battleJoinFailed : (String -> msg) -> Sub msg


port battleLeave : String -> Cmd msg


port battleLeaveSucceed : (String -> msg) -> Sub msg


port battleLeaveFailed : (String -> msg) -> Sub msg


port getBattleWinner : String -> Cmd msg


port getBattleWinnerSucceed : (String -> msg) -> Sub msg


port getBattleWinnerFailed : (String -> msg) -> Sub msg


port battleStart : String -> Cmd msg


port battleStartSucceed : (String -> msg) -> Sub msg


port battleStartFailed : (String -> msg) -> Sub msg


port battleSelPet : JD.Value -> Cmd msg


port battleSelPetSucceed : (String -> msg) -> Sub msg


port battleSelPetFailed : (String -> msg) -> Sub msg


port battleAttack : JD.Value -> Cmd msg


port battleAttackSucceed : (String -> msg) -> Sub msg


port battleAttackFailed : (String -> msg) -> Sub msg


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
        , listBattlesSucceed ListBattlesSucceed
        , listBattlesFailed GenericFailure
        , listElementsSucceed ListElementsSucceed
        , listElementsFailed GenericFailure
        , listPetTypesSucceed ListPetTypesSucceed
        , listPetTypesFailed GenericFailure
        , battleCreateSucceed BattleCreateSucceed
        , battleCreateFailed GenericFailure
        , battleJoinSucceed BattleJoinSucceed
        , battleJoinFailed GenericFailure
        , getBattleWinnerSucceed GetBattleWinnerSucceed
        , getBattleWinnerFailed GenericFailure
        , battleLeaveSucceed BattleLeaveSucceed
        , battleLeaveFailed GenericFailure
        , battleStartSucceed BattleStartSucceed
        , battleStartFailed GenericFailure
        , battleSelPetSucceed BattleSelPetSucceed
        , battleSelPetFailed GenericFailure
        , battleAttackSucceed BattleAttackSucceed
        , battleAttackFailed GenericFailure
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
    | ListBattlesSucceed JD.Value
    | ListElementsSucceed JD.Value
    | ListPetTypesSucceed JD.Value
    | BattleCreateSucceed String
    | BattleJoinSucceed String
    | BattleLeaveSucceed String
    | BattleStartSucceed String
    | BattleSelPetSucceed String
    | BattleAttackSucceed String
    | GenericFailure String
    | JoinBattle Battle
    | StartBattle Battle
    | LeaveBattle String
    | WatchBattle Battle
    | BattleSelectMonster Int
    | BattleSelPet Battle Int
    | BattleAttack Int Int
    | BattleAttackEnemy Int
    | BattleAttackSubmit Battle
    | BattleResetAttack
    | BattleCreate
    | GetBattleWinnerSucceed String
    | Logout
    | NoOp


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
                    , Cmd.batch [ listMonsters () ]
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
                ( { model | currentTime = time, notifications = notifications }, listBattles () )

        DeleteNotification id ->
            let
                notifications =
                    model.notifications
                        |> List.filter (\notification -> notification.id /= id)
            in
                ( { model | notifications = notifications }, Cmd.none )

        SetContent content ->
            let
                currentBattle =
                    case content of
                        ViewBattle b ->
                            Just b

                        _ ->
                            Nothing
            in
                ( { model
                    | content = content
                    , currentBattle = currentBattle
                    , battleLog = []
                    , battleNotifications = []
                    , battleWinner = Nothing
                    , battleSelectedMonster = 0
                    , battleSelectedAttackElement = 0
                    , battleSelectedAttackMonster = 0
                    , battleSelectedAttackEnemy = 0
                  }
                , Cmd.none
                )

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

        ListBattlesSucceed rawList ->
            case (JD.decodeValue battlesDecoder rawList) of
                Ok battles ->
                    let
                        -- filter current player battle
                        battle =
                            playerInBattles battles model.user.eosAccount
                                |> List.head

                        -- check player current battle
                        ( content, currentBattle ) =
                            case battle of
                                Just b ->
                                    ( ViewBattle b, Just b )

                                Nothing ->
                                    -- update current battle for watchers
                                    case model.currentBattle of
                                        Just b ->
                                            let
                                                newBattle =
                                                    battles
                                                        |> List.filter (\nb -> nb.host == b.host)
                                                        |> List.head
                                                        |> Maybe.withDefault b
                                            in
                                                ( ViewBattle newBattle, Just newBattle )

                                        Nothing ->
                                            ( model.content, model.currentBattle )

                        -- auto redirect to your battle in case you were not there
                        ( doRedirect, redirectCmd ) =
                            case currentBattle of
                                Just b ->
                                    case model.currentBattle of
                                        Just oldB ->
                                            if oldB.host /= b.host then
                                                ( True, showChat (b.host) )
                                            else
                                                ( False, Cmd.none )

                                        Nothing ->
                                            ( True, showChat (b.host) )

                                _ ->
                                    ( False, Cmd.none )

                        ( battleLog, battleWinner, battleNotifications ) =
                            if doRedirect then
                                ( [], Nothing, [] )
                            else
                                ( model.battleLog, model.battleWinner, model.battleNotifications )

                        -- update battle status
                        ( newBattleLog, newBattleNotifications ) =
                            case model.content of
                                ViewBattle battle ->
                                    let
                                        updatedBattle =
                                            battles
                                                |> List.filter (\b -> b.host == battle.host)
                                                |> List.head

                                        newBattleLog =
                                            case updatedBattle of
                                                Just newB ->
                                                    if newB /= battle then
                                                        addBattleLog model newB battle
                                                    else
                                                        ( battleLog, battleNotifications )

                                                Nothing ->
                                                    ( battleLog, battleNotifications )
                                    in
                                        newBattleLog

                                _ ->
                                    ( battleLog, battleNotifications )

                        -- if battle is over, we need to read the winner
                        finalCmd =
                            case currentBattle of
                                Just battle ->
                                    let
                                        battleIsOver =
                                            model.battlesInitialized
                                                && isBattleOver model.battles battle
                                                && model.battleWinner
                                                == Nothing
                                    in
                                        if battleIsOver then
                                            getBattleWinner (battle.host)
                                        else
                                            redirectCmd

                                Nothing ->
                                    redirectCmd
                    in
                        ( { model
                            | battles = battles
                            , battlesInitialized = True
                            , currentBattle = currentBattle
                            , battleLog = newBattleLog
                            , battleNotifications = newBattleNotifications
                            , battleWinner = battleWinner
                            , content = content
                          }
                        , finalCmd
                        )

                Err err ->
                    ( { model
                        | notifications = [ Notification (Error ("Fail to Parse Battles: " ++ err)) model.currentTime "parseBattlesFailed" ] ++ model.notifications
                      }
                    , Cmd.none
                    )

        GetBattleWinnerSucceed winner ->
            ( { model | battleWinner = Just winner }, Cmd.none )

        ListElementsSucceed rawList ->
            case (JD.decodeValue elementsDecoder rawList) of
                Ok elements ->
                    ( { model | elements = elements }, Cmd.none )

                Err err ->
                    ( { model
                        | notifications = [ Notification (Error ("Fail to Parse Elements: " ++ err)) model.currentTime "parseElementsFailed" ] ++ model.notifications
                      }
                    , Cmd.none
                    )

        ListPetTypesSucceed rawList ->
            case (JD.decodeValue petTypesDecoder rawList) of
                Ok petTypes ->
                    ( { model | petTypes = petTypes }, Cmd.none )

                Err err ->
                    ( { model
                        | notifications = [ Notification (Error ("Fail to Parse Pet Types: " ++ err)) model.currentTime "parsePetTypesFailed" ] ++ model.notifications
                      }
                    , Cmd.none
                    )

        BattleCreate ->
            ( model, battleCreate (1) )

        BattleCreateSucceed trxId ->
            ( model, Cmd.none )

        BattleJoinSucceed trxId ->
            ( { model
                | notifications =
                    [ Notification (Success "Battle Joined Successfully")
                        (model.currentTime - 7000)
                        "battleJoined"
                    ]
                        ++ model.notifications
              }
            , Cmd.none
            )

        BattleLeaveSucceed _ ->
            ( { model | content = BattleArena, currentBattle = Nothing }, Cmd.none )

        BattleStartSucceed trxId ->
            ( model, Cmd.none )

        BattleSelPetSucceed trxId ->
            ( model, Cmd.none )

        BattleAttackSucceed trxId ->
            ( { model
                | notifications =
                    [ Notification (Success "Attack submitted!")
                        (model.currentTime - 7000)
                        "attack"
                    ]
                        ++ model.notifications
                , battleSelectedAttackMonster = 0
                , battleSelectedAttackEnemy = 0
              }
            , Cmd.none
            )

        LeaveBattle host ->
            ( model, battleLeave (host) )

        JoinBattle battle ->
            let
                isInBattle =
                    playerInBattles model.battles model.user.eosAccount
                        |> List.length
                        |> (<) 0

                myAvailableMonsters =
                    availableMonstersToBattle model model.user.eosAccount ""
                        |> List.length

                errorMsg =
                    if isInBattle then
                        Just "You are already in a battle"
                    else if myAvailableMonsters < battle.mode then
                        Just "You don't have enough Available Monsters for this Battle"
                    else
                        Nothing
            in
                case errorMsg of
                    Just msg ->
                        ( { model
                            | notifications =
                                [ Notification (Error ("Fail to Join Battle: " ++ msg))
                                    model.currentTime
                                    "joinBattleFailed"
                                ]
                                    ++ model.notifications
                          }
                        , Cmd.none
                        )

                    Nothing ->
                        ( model, battleJoin (battle.host) )

        StartBattle battle ->
            ( model, battleStart (battle.host) )

        WatchBattle battle ->
            ( { model | content = ViewBattle battle, currentBattle = Just battle }, showChat (battle.host) )

        GenericFailure err ->
            handleMonsterAction model err "" False

        BattleSelPet battle petId ->
            let
                params =
                    JE.object
                        [ ( "host", JE.string battle.host )
                        , ( "petId", JE.int petId )
                        ]
            in
                ( model, battleSelPet (params) )

        BattleSelectMonster monsterId ->
            ( { model | battleSelectedMonster = monsterId }, Cmd.none )

        BattleResetAttack ->
            ( { model
                | battleSelectedAttackElement = 0
                , battleSelectedAttackMonster = 0
              }
            , Cmd.none
            )

        BattleAttack monsterId elementId ->
            ( { model
                | battleSelectedAttackElement = elementId
                , battleSelectedAttackMonster = monsterId
              }
            , Cmd.none
            )

        BattleAttackEnemy monsterId ->
            ( { model
                | battleSelectedAttackEnemy = monsterId
              }
            , Cmd.none
            )

        BattleAttackSubmit battle ->
            if
                model.battleSelectedAttackEnemy
                    > 0
                    && model.battleSelectedAttackMonster
                    > 0
            then
                let
                    params =
                        JE.object
                            [ ( "host", JE.string battle.host )
                            , ( "petId", JE.int model.battleSelectedAttackMonster )
                            , ( "petEnemyId", JE.int model.battleSelectedAttackEnemy )
                            , ( "element", JE.int model.battleSelectedAttackElement )
                            ]
                in
                    ( model, battleAttack (params) )
            else
                ( { model
                    | notifications =
                        [ Notification (Error ("Fail to Submit Attack: You need to select your monster power and at least one enemy monster"))
                            model.currentTime
                            "attackSubmissionRequestFail"
                        ]
                            ++ model.notifications
                  }
                , Cmd.none
                )

        NoOp ->
            ( model, Cmd.none )


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


addBattleLog : Model -> Battle -> Battle -> ( List BattleLog, List BattleNotification )
addBattleLog model newBattleLog oldBattle =
    let
        battleLogs =
            (BattleLog model.currentTime newBattleLog) :: model.battleLog

        newNotifications =
            newBattleLog.petsStats
                |> List.foldl
                    (\ps notifs ->
                        let
                            oldPs =
                                oldBattle.petsStats
                                    |> List.filter (\ops -> ops.petId == ps.petId)
                                    |> List.head
                        in
                            case oldPs of
                                Just ops ->
                                    if ps.hp /= ops.hp then
                                        (BattleNotification model.currentTime ps.petId HealthPoints (ps.hp - ops.hp)) :: notifs
                                    else
                                        notifs

                                Nothing ->
                                    notifs
                    )
                    []

        battleNotifications =
            newNotifications ++ model.battleNotifications
    in
        ( battleLogs, battleNotifications )


isBattleOver : List Battle -> Battle -> Bool
isBattleOver battles battle =
    List.length battle.petsStats
        > 0
        && (battles
                |> List.filter (\b -> b.host == battle.host && b.startedAt > 0)
                |> List.length
                |> (==) 0
           )


availableMonstersToBattle : Model -> String -> String -> List Monster
availableMonstersToBattle model player currentHost =
    model.monsters
        |> List.filter
            (\m ->
                if
                    m.owner
                        == player
                        && m.death_at
                        == 0
                        && not m.is_sleeping
                then
                    petInBattles model.battles m.id
                        |> List.filter
                            (\b ->
                                currentHost == "" || b.host /= currentHost
                            )
                        |> List.length
                        |> (==) 0
                else
                    False
            )


playerInBattle : Battle -> String -> Bool
playerInBattle battle player =
    battle.host
        == player
        || (battle.turns
                |> List.filter (\t -> t.player == player)
                |> List.length
                |> (<) 0
           )


waitingCommitments : Battle -> Bool
waitingCommitments battle =
    battle.turns
        |> List.filter (\t -> String.contains "0000000000000" t.reveal)
        |> List.length
        |> (<) 0


waitingPicks : Battle -> Bool
waitingPicks battle =
    battle.petsStats
        |> List.length
        -- 1v1 = 2 pets, 2v2 = 4 pets, 3v3 = 6 pets
        |> (/=) (battle.mode * 2)


isStarted : Battle -> Bool
isStarted battle =
    battle.startedAt > 0 && battle.lastMoveAt > 0


battlePhase : List Battle -> Battle -> BattlePhase
battlePhase battles battle =
    if isBattleOver battles battle then
        BattleFinishedPhase
    else if List.length battle.turns < battlePlayersQty then
        BattleJoiningPhase
    else if waitingCommitments battle then
        BattleStartingPhase
    else if waitingPicks battle then
        BattlePickingPhase
    else if isStarted battle then
        BattleOnGoingPhase
    else
        BattleUnknownPhase


petInBattle : Battle -> Int -> Bool
petInBattle battle petId =
    battle.petsStats
        |> List.filter (\ps -> ps.petId == petId)
        |> List.length
        |> (<) 0


playerInBattles : List Battle -> String -> List Battle
playerInBattles battles player =
    battles
        |> List.filter
            (\b -> playerInBattle b player)


petInBattles : List Battle -> Int -> List Battle
petInBattles battles petId =
    battles
        |> List.filter
            (\b -> petInBattle b petId)


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
        |> JDP.required "battle_max_arenas" JD.int
        |> JDP.required "battle_idle_tolerance" JD.int



-- TODO: adjust above hardcode before release


elementsDecoder : JD.Decoder (List Element)
elementsDecoder =
    JD.list
        (JDP.decode Element
            |> JDP.required "id" JD.int
            |> JDP.required "name" JD.string
            |> JDP.required "ratios" (JD.list JD.int)
        )


petTypesDecoder : JD.Decoder (List PetType)
petTypesDecoder =
    JD.list
        (JDP.decode PetType
            |> JDP.required "id" JD.int
            |> JDP.required "elements" (JD.list JD.int)
        )


petsStatsDecoder : JD.Decoder (List BattlePetStat)
petsStatsDecoder =
    JD.list
        (JDP.decode BattlePetStat
            |> JDP.required "pet_id" JD.int
            |> JDP.required "pet_type" JD.int
            |> JDP.required "player" JD.string
            |> JDP.required "hp" JD.int
        )


commitsDecoder : JD.Decoder (List BattleCommit)
commitsDecoder =
    JD.list
        (JDP.decode BattleCommit
            |> JDP.required "player" JD.string
            |> JDP.required "commitment" JD.string
            |> JDP.required "reveal" JD.string
        )


battlesDecoder : JD.Decoder (List Battle)
battlesDecoder =
    JD.list
        (JDP.decode Battle
            |> JDP.required "host" JD.string
            |> JDP.required "mode" JD.int
            |> JDP.required "startedAt" JD.float
            |> JDP.required "lastMoveAt" JD.float
            |> JDP.required "commits" commitsDecoder
            |> JDP.required "pets_stats" petsStatsDecoder
        )


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

        battle =
            case model.content of
                ViewBattle b ->
                    if playerInBattle b model.user.eosAccount then
                        Just b
                    else
                        Nothing

                _ ->
                    Nothing

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
            else if battle /= Nothing then
                [ p [ class "navbar-item greetings" ]
                    [ loadingIcon model
                    , text "Hello"
                    , span [] [ b [] [ text model.user.eosAccount ] ]
                    , text "! Looks like you are in a battle!"
                    ]
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

                BattleArena ->
                    defaultContent (battleArenaContent model)

                ViewBattle battle ->
                    defaultContent (battleContent model battle)

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


monsterImgSrc : Int -> String
monsterImgSrc mtype =
    "images/monsters/monster-" ++ (toString mtype) ++ ".png"


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
                        [ img [ alt monster.name, class sleepingClass, src (monsterImgSrc monster.mtype) ]
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


battleCard : Model -> Battle -> Html Msg
battleCard model battle =
    let
        started =
            battle.startedAt > 0

        monstersAlive =
            battle.petsStats
                |> List.filter (\ps -> ps.hp > 0)
                |> List.length

        ( startedAt, lastTurnAt, monstersAliveTxt ) =
            if battle.startedAt > 0 then
                ( calcTimeDiff model.currentTime battle.startedAt
                , calcTimeDiff model.currentTime battle.lastMoveAt
                , toString monstersAlive
                )
            else
                ( "Pending", "N/A", "N/A" )

        ( joinButtonText, joinButtonAction ) =
            if List.length battle.turns >= 2 then
                ("Full, you can Watch", (WatchBattle battle))
            else
                ("Join Battle", (JoinBattle battle))
    in
        div [ class "card" ]
            [ header [ class "card-header" ]
                [ p [ class "card-header-title" ]
                    [ text (battle.host ++ "'s Arena") ]
                ]
            , div [ class "card-content" ]
                [ div [ class "content" ]
                    [ nav [ class "level" ]
                        [ div [ class "level-item has-text-centered" ]
                            [ div []
                                [ p [ class "heading" ]
                                    [ text "Start Time" ]
                                , p [ class "title" ]
                                    [ text startedAt ]
                                ]
                            ]
                        , div [ class "level-item has-text-centered" ]
                            [ div []
                                [ p [ class "heading" ]
                                    [ text "Last Turn" ]
                                , p [ class "title" ]
                                    [ text lastTurnAt ]
                                ]
                            ]
                        , div [ class "level-item has-text-centered" ]
                            [ div []
                                [ p [ class "heading" ]
                                    [ text "Mode" ]
                                , p [ class "title" ]
                                    [ text "1v1" ]
                                ]
                            ]
                        , div [ class "level-item has-text-centered" ]
                            [ div []
                                [ p [ class "heading" ]
                                    [ text "Monsters Alive" ]
                                , p [ class "title" ]
                                    [ text monstersAliveTxt ]
                                ]
                            ]
                        ]
                    ]
                ]
            , footer [ class "card-footer" ]
                [ a [ class "card-footer-item", onClick joinButtonAction ]
                    [ text joinButtonText ]
                , a [ class "card-footer-item", onClick (WatchBattle battle) ]
                    [ text "Watch" ]
                ]
            ]


battleArenaContent : Model -> Html Msg
battleArenaContent model =
    let
        currentPlaying =
            playerInBattles model.battles model.user.eosAccount
                |> List.head

        currentBattles =
            List.length model.battles

        availableArenas =
            model.globalConfig.maxArenas - currentBattles

        availableArenasTxt =
            toString availableArenas

        maxArenasTxt =
            toString model.globalConfig.maxArenas

        hostButton =
            case currentPlaying of
                Just battle ->
                    a
                        [ class "button is-warning"
                        , onClick (SetContent (ViewBattle battle))
                        , disabledAttribute model.isLoading
                        ]
                        [ text "Reconnect to Battle" ]

                Nothing ->
                    a
                        [ class "button is-success"
                        , onClick BattleCreate
                        , disabledAttribute model.isLoading
                        ]
                        [ text "Create a Battle" ]

        battleListHeader =
            if currentBattles > 0 then
                text "Check the current battles below to join or watch!"
            else
                text "No one is battling! Why don't you create a new Battle?"
    in
        div []
            [ div [ class "content" ]
                [ titleMenu "Welcome to the Arena!"
                    [ span [] [ text ("Available Arenas: " ++ availableArenasTxt ++ "/" ++ maxArenasTxt) ]
                    , hostButton
                    ]
                , p [] [ battleListHeader ]
                ]
            , div [] (model.battles |> List.map (\b -> battleCard model b))
            ]


battleMonstersPick : Model -> Battle -> Maybe BattleCommit -> Html Msg
battleMonstersPick model battle commitment =
    let
        myAccount =
            model.user.eosAccount

        displayTurns =
            battle.turns
                |> List.sortWith
                    (\a b ->
                        if a.player == myAccount then
                            LT
                        else
                            EQ
                    )

        myBattle =
            playerInBattle battle myAccount

        isReady =
            battle.turns
                |> List.filter (\t -> t.player == myAccount && not (String.contains "00000000" t.reveal))
                |> List.length
                |> (==) 1

        footer =
            case commitment of
                Nothing ->
                    let
                        commitmentText =
                            p [] [ text "Each player will be able to choose one of the above monsters." ]

                        commitmentContent =
                            if not isReady && myBattle then
                                [ commitmentText
                                , a [ class "button is-success is-large has-margin-top", onClick (StartBattle battle) ] [ text "I'm Ready to Battle!" ]
                                ]
                            else
                                [ commitmentText
                                , a [ class "button is-warning is-large has-margin-top", disabledAttribute True ] [ text "Waiting for Players" ]
                                ]
                    in
                        commitmentContent

                Just commit ->
                    if commit.player == myAccount then
                        let
                            ( action, disabled ) =
                                if model.battleSelectedMonster > 0 then
                                    ( BattleSelPet battle model.battleSelectedMonster
                                    , disabledAttribute False
                                    )
                                else
                                    ( NoOp, disabledAttribute True )
                        in
                            [ a [ class "button is-success is-large has-margin-top", onClick action, disabled ] [ text "Confirm Pick" ] ]
                    else
                        [ p [] [ text ("Wait your turn to pick") ] ]
    in
        div [ class "monster-picks" ]
            [ div [ class "columns" ]
                (displayTurns
                    |> List.map
                        (\t ->
                            let
                                availableMonsters =
                                    availableMonstersToBattle model t.player battle.host

                                isReady =
                                    not (String.contains "00000000" t.reveal)

                                ( statusTxt, statusClass ) =
                                    if isReady then
                                        ( "Ready", "has-text-success" )
                                    else
                                        ( "Pending", "has-text-danger" )

                                monsterIcon monster =
                                    let
                                        monsterClass =
                                            if
                                                model.battleSelectedMonster
                                                    == monster.id
                                                    || petInBattle battle monster.id
                                            then
                                                "active"
                                            else
                                                ""

                                        action =
                                            if monster.owner == myAccount then
                                                BattleSelectMonster monster.id
                                            else
                                                NoOp
                                    in
                                        div [ class ("monster-pick " ++ monsterClass) ]
                                            [ figure [ class "image", onClick action ]
                                                [ img [ src (monsterImgSrc monster.mtype) ] []
                                                ]
                                            ]
                            in
                                div [ class "column" ]
                                    [ h3 [ class "title is-4" ]
                                        [ text t.player
                                        , small [ class statusClass ] [ text statusTxt ]
                                        ]
                                    , div [ class "player-monsters" ]
                                        (availableMonsters
                                            |> List.map monsterIcon
                                        )
                                    ]
                        )
                )
            , div [ class "has-text-centered" ] footer
            ]


getArena : Float -> String
getArena startedAt =
    let
        arenaCode =
            (floor startedAt) % availableArenas
    in
        toString arenaCode


elementButton : Int -> Msg -> String -> Html Msg
elementButton elementTypeId msg displayText =
    let
        ( elementClass, elementIcon ) =
            case elementTypeId of
                1 ->
                    ( "is-brown", "tree" )

                2 ->
                    ( "is-success", "leaf" )

                3 ->
                    ( "is-info", "tint" )

                4 ->
                    ( "is-danger", "fire" )

                5 ->
                    ( "is-dark", "wrench" )

                6 ->
                    ( "is-primary", "paw" )

                7 ->
                    ( "is-purple", "bug" )

                8 ->
                    ( "is-black", "adjust" )

                9 ->
                    ( "is-warning", "bolt" )

                _ ->
                    ( "", "asterisk" )

        textSpan =
            if String.isEmpty displayText then
                text ""
            else
                span [] [ text displayText ]
    in
        a [ class ("button is-small " ++ elementClass), onClick msg ]
            [ icon elementIcon False False
            , textSpan
            ]


attackButtons : Model -> BattlePetStat -> Html Msg
attackButtons model monster =
    if model.battleSelectedAttackMonster == 0 then
        let
            petType =
                model.petTypes
                    |> List.filter (\pt -> pt.id == monster.petType)
                    |> List.head

            buttons =
                case petType of
                    Just pt ->
                        pt.elements
                            |> List.map (\e -> elementButton e (BattleAttack monster.petId e) "")

                    Nothing ->
                        [ text "No Available Attacks" ]
        in
            div [ class "buttons elements" ] buttons
    else
        let
            element =
                model.elements
                    |> List.filter (\el -> el.id == model.battleSelectedAttackElement)
                    |> List.head

            attackDisplayButton =
                case element of
                    Just el ->
                        elementButton model.battleSelectedAttackElement
                            NoOp
                            (el.name ++ " Attack")

                    Nothing ->
                        text "Error: Element not Found"

            cancelAttackButton =
                a [ class "button is-danger is-small", onClick BattleResetAttack ] [ icon "ban" False False ]
        in
            div [ class "buttons elements" ]
                [ attackDisplayButton
                , cancelAttackButton
                ]


hpBar : Int -> String -> Html msg
hpBar hp monsterName =
    let
        hpClass =
            if hp > 65 then
                "is-success"
            else if hp > 30 then
                "is-warning"
            else
                "is-danger"
    in
        div []
            [ progress
                [ class ("progress " ++ hpClass), attribute "value" (toString hp), attribute "max" "100" ]
                [ text (toString hp ++ "%") ]
            , span [ class "monster-hp-name" ] [ text monsterName ]
            ]


battleOnGoingArena : Model -> Battle -> Bool -> Html Msg
battleOnGoingArena model battle myTurn =
    let
        arenaCode =
            getArena battle.startedAt

        myAccount =
            model.user.eosAccount

        myBattle =
            playerInBattle battle myAccount

        arenaMonsters =
            battle.petsStats
                |> List.map
                    (\monster ->
                        let
                            attacksControl =
                                if myTurn && monster.player == myAccount then
                                    attackButtons model monster
                                else
                                    text ""

                            ( monsterSelAction, monsterClass ) =
                                if monster.player == myAccount then
                                    ( NoOp, "my-monster" )
                                else
                                    ( BattleAttackEnemy monster.petId, "enemy-monster" )

                            monsterFinalClass =
                                if monster.petId == model.battleSelectedAttackEnemy then
                                    monsterClass ++ " active"
                                else
                                    monsterClass

                            monsterData =
                                model.monsters
                                    |> List.filter (\m -> m.id == monster.petId)
                                    |> List.head

                            monsterName =
                                case monsterData of
                                    Just m ->
                                        m.name

                                    Nothing ->
                                        "Unknown"

                            monsterHpNotification =
                                model.battleNotifications
                                    |> List.filter
                                        (\bn ->
                                            bn.petId
                                                == monster.petId
                                                && bn.time
                                                > (model.currentTime - hpNotificationSeconds)
                                                && bn.nType
                                                == HealthPoints
                                        )
                                    |> List.head

                            monsterHpNotificationSpan =
                                case monsterHpNotification of
                                    Just notif ->
                                        span [ class "monster-hp-notification" ] [ text (toString notif.hp) ]

                                    Nothing ->
                                        text ""

                            winner =
                                Maybe.withDefault "" model.battleWinner

                            hasWinner =
                                winner /= ""

                            monsterHp =
                                if hasWinner && winner /= monster.player then
                                    0
                                else
                                    monster.hp
                        in
                            div [ class ("arena-monster " ++ monsterFinalClass), onClick monsterSelAction ]
                                [ figure [ class "image" ]
                                    [ img [ src (monsterImgSrc monster.petType) ] []
                                    ]
                                , monsterHpNotificationSpan
                                , hpBar monsterHp monsterName
                                , attacksControl
                                ]
                    )

        winnerBanner =
            case model.battleWinner of
                Just winner ->
                    let
                        ( winnerMsg, winnerClass ) =
                            if myAccount == winner then
                                ( "You WON!", "has-text-success" )
                            else if myBattle then
                                ( "You LOST", "has-text-danger" )
                            else
                                ( winner ++ " WON!", "has-text-info" )
                    in
                        div [ class ("battle-winner-banner " ++ winnerClass) ]
                            [ text winnerMsg ]

                Nothing ->
                    text ""
    in
        div [ class ("battle-arena arena-" ++ arenaCode) ]
            (winnerBanner
                :: arenaMonsters
            )


myBattleActions : Model -> Battle -> Html Msg
myBattleActions model battle =
    div [ class "battle-actions" ]
        [ (if model.battleSelectedAttackMonster == 0 then
            text "Please choose an Attack from your Monsters"
           else if model.battleSelectedAttackEnemy == 0 then
            text "Please choose an Enemy Monster that you want to Attack"
           else
            a [ class "button is-success", onClick (BattleAttackSubmit battle) ]
                [ text "Confirm Attack and End Turn" ]
          )
        ]


battleContent : Model -> Battle -> Html Msg
battleContent model battle =
    let
        myBattle =
            playerInBattle battle model.user.eosAccount

        phase =
            battlePhase model.battles battle

        turnSeconds =
            (model.currentTime - battle.lastMoveAt) / 1000

        turnTimeoutSeconds =
            model.globalConfig.battleIdleTolerance - (floor turnSeconds)

        isTurnTimeout =
            turnTimeoutSeconds < 0

        turnTimeoutClass =
            if turnTimeoutSeconds < 6 then
                "has-text-danger"
            else
                "has-text-info"

        turnTimeoutTxt =
            if phase == BattleFinishedPhase then
                ""
            else if isTurnTimeout then
                "Turn TIMEOUT! Anyone can ATTACK!"
            else
                "Turn Countdown: " ++ toString turnTimeoutSeconds

        currentTurnStatus =
            if phase == BattleOnGoingPhase then
                span [ class turnTimeoutClass ] [ text turnTimeoutTxt ]
            else
                text ""

        leftStatusClass =
            if phase == BattleFinishedPhase then
                "has-text-info"
            else if (phase == BattleOnGoingPhase && isTurnTimeout) then
                "has-text-danger"
            else
                ""

        ( statusText, content, turnActions ) =
            case phase of
                BattleJoiningPhase ->
                    ( "Joining Phase: Waiting for players"
                    , text ""
                    , text ""
                    )

                BattleStartingPhase ->
                    ( "Starting Phase: Waiting for players confirmation"
                    , battleMonstersPick model battle Nothing
                    , text ""
                    )

                BattlePickingPhase ->
                    let
                        pickPlayer =
                            battle.turns
                                |> List.head
                    in
                        case pickPlayer of
                            Just commit ->
                                ( "Picking Phase: Waiting for Player " ++ commit.player ++ " pick"
                                , battleMonstersPick model battle (Just commit)
                                , text ""
                                )

                            Nothing ->
                                ( "Picking Phase: No players to Pick?"
                                , battleMonstersPick model battle Nothing
                                , text ""
                                )

                BattleOnGoingPhase ->
                    let
                        attackPlayer =
                            battle.turns
                                |> List.head

                        myAccount =
                            model.user.eosAccount
                    in
                        case attackPlayer of
                            Just commit ->
                                let
                                    statusMsg =
                                        if isTurnTimeout then
                                            "Battle On Going: Waiting for ANY PLAYER attack"
                                        else
                                            "Battle On Going: Waiting for Player " ++ commit.player ++ "'s attack"

                                    myTurn =
                                        (commit.player == myAccount || isTurnTimeout)

                                    myTurnActions =
                                        if myTurn then
                                            myBattleActions model battle
                                        else
                                            text ""
                                in
                                    ( statusMsg
                                    , battleOnGoingArena model
                                        battle
                                        myTurn
                                    , myTurnActions
                                    )

                            Nothing ->
                                ( "Battle On Going: No Players to Attack?"
                                , battleOnGoingArena model battle True
                                , text ""
                                )

                BattleFinishedPhase ->
                    ( "Battle is OVER - Now you can leave!"
                    , battleOnGoingArena model battle False
                    , text ""
                    )

                BattleUnknownPhase ->
                    ( "Battle Unknown"
                    , text ""
                    , text ""
                    )

        backButton =
            if myBattle then
                text ""
            else
                a
                    [ class "button is-success"
                    , onClick (SetContent BattleArena)
                    , disabledAttribute model.isLoading
                    ]
                    [ text "Back to Battles List" ]

        leaveAction =
            if phase == BattleFinishedPhase then
                SetContent BattleArena
            else
                LeaveBattle battle.host

        leaveButton =
            if myBattle && (phase == BattleStartingPhase || phase == BattleJoiningPhase || phase == BattleFinishedPhase) then
                a
                    [ class "button is-danger"
                    , onClick leaveAction
                    ]
                    [ text "Leave Battle" ]
            else
                text ""
    in
        div []
            [ div [ class "content" ]
                [ div [ class "box" ]
                    [ titleMenu (battle.host ++ "'s Arena")
                        [ currentTurnStatus
                        , leaveButton
                        , backButton
                        ]
                    , div [ class "level" ]
                        [ div [ class "level-left" ]
                            [ div [ class ("level-item " ++ leftStatusClass) ]
                                [ text statusText ]
                            ]
                        , div [ class "level-right" ]
                            [ div [ class "level-item" ]
                                [ turnActions ]
                            ]
                        ]
                    ]
                ]
            , content
            , div [ class "tlk-webchat has-margin-top" ] [ text "" ]
            ]


webchat : String -> Html msg
webchat str =
    div [ id str ] [ text "" ]


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
                        [ class "button is-success"
                        , onClick ToggleMonsterCreation
                        , disabledAttribute model.isLoading
                        ]
                        [ text "New Monster" ]
                    , a
                        [ class "button is-info"
                        , onClick (SetContent BattleArena)
                        , disabledAttribute model.isLoading
                        ]
                        [ text "Battle Arena" ]
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
