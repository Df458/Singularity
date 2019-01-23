libsrc = files(
    'AppSettings.vala', 
    'AtomItemDataSource.vala', 
    'Attachment.vala', 
    'CollectionNode.vala', 
    'CollectionRequest.vala',
    'CollectionTreeStore.vala', 
    'ColumnViewBuilder.vala',
    'DatabaseManager.vala', 
    'DatabaseRequest.vala',
    'DataSource.vala', 
    'DeleteCollectionRequest.vala',
    'Feed.vala', 
    'FeedCollection.vala', 
    'FeedProvider.vala', 
    'GridViewBuilder.vala', 
    'IconRequest.vala',
    'IO.vala',
    'Item.vala', 
    'ItemToggleRequest.vala',
    'ItemViewRequest.vala',
    'LoadFeedsRequest.vala',
    'OPMLFeedDataSource.vala',
    'Person.vala',
    'RenameRequest.vala',
    'ReversibleDataSource.vala',
    'RSSItemDataSource.vala',
    'StreamViewBuilder.vala',
    'SubscribeRequest.vala',
    'Tag.vala',
    'UnsubscribeRequest.vala',
    'UpdateGenerator.vala',
    'UpdatePackage.vala',
    'UpdatePackageRequest.vala',
    'UpdateParentRequest.vala',
    'UpdateQueue.vala',
    'ViewBuilder.vala',
    'XmlRequest.vala'
  )
libcsrc = ['jshandler.c']

libctarget = static_library('jshandler', libcsrc,
                            dependencies : deps,
                            install : false)
libtarget = static_library('singularity', libsrc,
                            dependencies : deps,
                            install : false)

if lint.found()
    run_target(
        'lint-lib',
        command: [
            lint,
        ] + libsrc)
endif
