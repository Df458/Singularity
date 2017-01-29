libsrc = ['AtomItemDataSource.vala', 'Attachment.vala', 'CollectionNode.vala', 'CollectionTreeStore.vala', 'DataLocator.vala', 'DataSource.vala', 'DatabaseManager.vala', 'Feed.vala', 'FeedCollection.vala', 'FeedProvider.vala', 'GlobalSettings.vala', 'GridViewBuilder.vala', 'IO.vala', 'Item.vala', 'OPMLFeedDataSource.vala', 'Person.vala', 'RSSItemDataSource.vala', 'ReversibleDataSource.vala', 'SessionSettings.vala', 'StreamViewBuilder.vala', 'Tag.vala', 'UpdateGenerator.vala', 'UpdatePackage.vala', 'UpdateQueue.vala', 'ViewBuilder.vala', 'XmlRequest.vala', 'ItemListRequest.vala', 'DatabaseRequest.vala', 'UpdatePackageRequest.vala', 'UnsubscribeRequest.vala', 'ItemViewRequest.vala', 'ItemToggleRequest.vala', 'SubscribeRequest.vala', 'LoadFeedsRequest.vala', 'IconRequest.vala', 'ColumnViewBuilder.vala']
libcsrc = ['jshandler.c']

libctarget = static_library('jshandler', libcsrc,
                            dependencies : deps,
                            install : false)
libtarget = static_library('singularity', libsrc,
                            dependencies : deps,
                            install : false)
