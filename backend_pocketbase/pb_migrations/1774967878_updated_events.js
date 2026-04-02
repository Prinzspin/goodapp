/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1687431684")

  // update collection data
  unmarshal({
    "viewRule": "is_public = true || creator = @request.auth.id || event_members_via_event.user ?= @request.auth.id && event_members_via_event.status ?= \"accepted\""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1687431684")

  // update collection data
  unmarshal({
    "viewRule": "is_public = true || creator = @request.auth.id || @collection.event_members.event = id && @collection.event_members.user = @request.auth.id && @collection.event_members.status = \"accepted\""
  }, collection)

  return app.save(collection)
})
