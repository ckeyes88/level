defmodule LevelWeb.GraphQL.GroupPostsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query GetGroupPosts(
      $space_id: ID!,
      $group_id: ID!
    ) {
      space(id: $space_id) {
        group(id: $group_id) {
          posts(first: 20) {
            edges {
              node {
                body
                body_html
                author {
                  firstName
                }
                replies(last: 5) {
                  edges {
                    node {
                      body
                      author {
                        firstName
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space_user: space_user} = result} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{group: group}} = create_group(space_user)

    result =
      result
      |> Map.put(:group, group)
      |> Map.put(:conn, conn)

    {:ok, result}
  end

  test "groups have a posts connection", %{
    conn: conn,
    space_user: space_user,
    group: group
  } do
    {:ok, %{post: post}} = post_to_group(space_user, group, %{body: "Hey!"})
    {:ok, _reply} = reply_to_post(space_user, post, %{body: "Sup?"})

    variables = %{
      space_id: space_user.space_id,
      group_id: group.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "group" => %{
                   "posts" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "body" => "Hey!",
                           "body_html" => "<p>Hey!</p>\n",
                           "author" => %{
                             "firstName" => space_user.first_name
                           },
                           "replies" => %{
                             "edges" => [
                               %{
                                 "node" => %{
                                   "body" => "Sup?",
                                   "author" => %{
                                     "firstName" => space_user.first_name
                                   }
                                 }
                               }
                             ]
                           }
                         }
                       }
                     ]
                   }
                 }
               }
             }
           }
  end
end
