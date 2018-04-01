module Config
    exposing
        ( batchUrl
        , messagesUrl
        , threadsUrl
        , labelsUrl
        )


rootUrl : String
rootUrl =
    "https://www.googleapis.com"


servicePath : String
servicePath =
    "gmail/v1/users/me"


batchUrl : String
batchUrl =
    "https://content.googleapis.com/batch/gmail/v1"


messagesUrl : String
messagesUrl =
    String.join "/"
        [ rootUrl, servicePath, "messages" ]


threadsUrl : String
threadsUrl =
    String.join "/"
        [ rootUrl, servicePath, "threads" ]


labelsUrl : String
labelsUrl =
    String.join "/"
        [ rootUrl, servicePath, "labels" ]
