module Data.Post exposing (Post, fragment, decoder, appendReply, groupsInclude)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, list, string)
import Json.Decode.Pipeline as Pipeline
import Connection exposing (Connection)
import Data.Group exposing (Group)
import Data.Reply exposing (Reply)
import Data.SpaceUser exposing (SpaceUser)
import GraphQL exposing (Fragment)
import Util exposing (dateDecoder, memberById)


-- TYPES


type alias Post =
    { id : String
    , body : String
    , bodyHtml : String
    , author : SpaceUser
    , groups : List Group
    , postedAt : Date
    , replies : Connection Reply
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment PostFields on Post {
          id
          body
          bodyHtml
          postedAt
          author {
            ...SpaceUserFields
          }
          groups {
            ...GroupFields
          }
          replies(last: 10) {
            ...ReplyConnectionFields
          }
        }
        """
        [ Data.SpaceUser.fragment
        , Data.Group.fragment
        , Connection.fragment "ReplyConnection" Data.Reply.fragment
        ]



-- DECODERS


decoder : Decoder Post
decoder =
    Pipeline.decode Post
        |> Pipeline.required "id" string
        |> Pipeline.required "body" string
        |> Pipeline.required "bodyHtml" string
        |> Pipeline.required "author" Data.SpaceUser.decoder
        |> Pipeline.required "groups" (list Data.Group.decoder)
        |> Pipeline.required "postedAt" dateDecoder
        |> Pipeline.required "replies" (Connection.decoder Data.Reply.decoder)



-- CRUD


appendReply : Reply -> Post -> Post
appendReply reply post =
    { post | replies = Connection.append reply post.replies }


groupsInclude : Group -> Post -> Bool
groupsInclude group post =
    memberById group post.groups
