module Config exposing (messagesUrl, threadsUrl)


apiUrl : String
apiUrl =
    "https://www.googleapis.com/gmail/v1/users/me"


messagesUrl : String
messagesUrl =
    String.join "/"
        [ apiUrl, "messages" ]


threadsUrl : String
threadsUrl =
    String.join "/"
        [ apiUrl, "threads" ]
