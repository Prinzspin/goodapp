/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_700663329")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\" && @request.auth.id = user",
    "deleteRule": "@request.auth.id = user || @collection.events.creator = @request.auth.id",
    "indexes": [
      "CREATE UNIQUE INDEX `idx_sdGKuPnHrY` ON `event_members` (\n  `event`,\n  `user`\n)"
    ],
    "updateRule": "@collection.events.creator = @request.auth.id"
  }, collection)

  // add field
  collection.fields.addAt(3, new Field({
    "cascadeDelete": false,
    "collectionId": "_pb_users_auth_",
    "hidden": false,
    "id": "relation2375276105",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "user",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "select2063623452",
    "maxSelect": 1,
    "name": "status",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "pending",
      "accepted",
      "rejected"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_700663329")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\"",
    "deleteRule": "@request.auth.id != \"\"",
    "indexes": [
      "CREATE UNIQUE INDEX `idx_sdGKuPnHrY` ON `event_members` (`event`)"
    ],
    "updateRule": "@request.auth.id != \"\""
  }, collection)

  // remove field
  collection.fields.removeById("relation2375276105")

  // remove field
  collection.fields.removeById("select2063623452")

  return app.save(collection)
})
