/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_700663329")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\"",
    "deleteRule": "@request.auth.id != \"\"",
    "indexes": [
      "CREATE UNIQUE INDEX `idx_sdGKuPnHrY` ON `event_members` (`event`)"
    ]
  }, collection)

  // remove field
  collection.fields.removeById("relation2375276105")

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_700663329")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\" && @request.auth.id = user",
    "deleteRule": "@request.auth.id = user || @collection.events.creator = @request.auth.id",
    "indexes": [
      "CREATE UNIQUE INDEX `idx_sdGKuPnHrY` ON `event_members` (\n  `event`,\n  `user`\n)"
    ]
  }, collection)

  // add field
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "relation2375276105",
    "maxSelect": 1,
    "name": "user",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "pending",
      "accepted",
      "rejected"
    ]
  }))

  return app.save(collection)
})
