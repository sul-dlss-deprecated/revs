Revs::Application.routes.draw do

  root :to => "catalog#index"

  match "bookmarks", :to => "application#routing_error" # we are not using blacklight bookmarks, so a request to get them should fail nicely

  Blacklight.add_routes(self)

  # override devise controllers as needed
  devise_for :users, :controllers => { :sessions => "sessions", :registrations=>"registrations", :passwords=>"passwords" } # extend the default devise session controller with our own to override some methods

  # ajax calls to confirm uniqueness of email and username as a convience to user before they submit the form
  devise_scope :user do
    match 'check_username', :to=>"registrations#check_username", :via=>:post
    match 'check_email', :to=>"registrations#check_email", :via=>:post
    match 'users/edit_account', :to=>"registrations#edit_account", :as=>'edit_user_account', :via=>:get
    match 'users/update_account', :to=>"registrations#update_account", :as=>'update_user_account', :via=>:put
    match "users/webauth_login" => "sessions#webauth_login", :as => "webauth_login", :via=>:get
    match "users/webauth_logout" => "sessions#webauth_logout", :as => "webauth_logout", :via=>:delete
  end
    
  # version and faq pages
  match 'version', :to=>'about#show', :defaults => {:id=>'version'}, :as => 'version'
  match 'faq', :to=>'about#show', :defaults => {:id=>'faq'}, :as => 'faq'
  
  match 'search', :to=> 'catalog#index', :as=>'search'
  
  match 'autocomplete', :to=>'catalog#autocomplete', :as=>'autocomplete', :via=>:get

  # all collections pages helper route
  match 'collection', :to => 'collection#index', :as => 'all_collections'

  # ajax call from home page to get more images for the carousel
  match 'update_carousel', :to => 'catalog#update_carousel', :as => 'update_carousel'

  # ajax call from item page to show collections grid at bottom of the page
  match 'show_collection_members_grid/:id', :to => 'catalog#show_collection_members_grid', :as => 'show_collection_members_grid'
  
  # helper routes to we can have a friendly URL for items and collections
  match ':id', :to=>'catalog#show', :constraints => {:id => /[a-z]{2}\d{3}[a-z]{2}\d{4}/}  # so that /DRUID goes to the item page
  match 'item/:id', :to=> 'catalog#show', :as =>'item', :constraints => {:id => /[a-z]{2}\d{3}[a-z]{2}\d{4}/}
  match 'collection/:id', :to=> 'catalog#show', :as =>'collection', :constraints => {:id => /[a-z]{2}\d{3}[a-z]{2}\d{4}/}
  
  # public user profile pages
  resources :user do
    collection do
      match ':id/favorites', :to=>'user#favorites', :as=>'user_favorites', :via=>:get, :constraints => {:id => /\w+.+/} 
      match ':id/galleries', :to=>'user#galleries', :as=>'user_galleries', :via=>:get, :constraints => {:id => /\w+.+/} 
      match ':id/annotations', :to=>'user#annotations', :as=>'user_annotations', :via=>:get, :constraints => {:id => /\w+.+/} 
      match ':id/flags', :to=>'user#flags', :as=>'user_flags', :via=>:get, :constraints => {:id => /\w+.+/} 
      match ':id/edits', :to=>'user#edits', :as=>'user_edits', :via=>:get, :constraints => {:id => /\w+.+/} 
      match ':id', :to=>'user#show', :via=>:get, :constraints => {:id => /\w+.+/} 
    end
  end
  
  # Handles all About pages.
  match 'about', :to => 'about#show', :as => 'about_project', :defaults => {:id=>'project'} # no page specified, go to project page
  match 'contact', :to=> 'about#contact', :as=>'contact_us'
  match 'about/contact', :to=> 'about#contact' # specific contact us about page
  match 'about/tutorials', :to=> 'about#tutorials', :as => 'tutorials' # specific tutorials list page
  match 'about/boom', :to => 'about#boom' # test exception
  match 'about/:id', :to => 'about#show', :as=>'about_pages' # catch anything else and direct to show page with ID parameter of partial to show
  
  # term acceptance dialog
  match 'accept_terms', :to=> 'application#accept_terms', :as=> 'accept_terms', :via=>:post
  
  # bulk metadata editing
  post 'catalog', :to=>'catalog#index', :as=>'bulk_edit'
  
  resources :annotations do
    collection do
      get 'for_image/:id', :to => 'annotations#index_by_druid'
    end
  end
  
  resources :galleries
  resources :saved_items do
    collection do
      get 'cancel/:id', :to => 'saved_items#cancel', :as=>'cancel'
      post 'sort', :to => 'saved_items#sort', :as=>'sort'
      post 'manage', :to => 'saved_items#manage', :as=>'manage'
    end
  end
    
  resources :flags do
    collection do
      get 'for_image/:id', :to => 'flags#index_by_druid'
      get 'update_flag_table', :to => 'user#update_flag_table'
      get 'update_curator_flag_table', :to => 'user#curator_update_flag_table'
    end
  end

  # admin pages
  get 'admin', :to => 'admin#index', :as=>'admin_dashboard' # admin dashboard
  namespace :admin do
    resources :users do
      collection do
        post 'bulk_update_role', :to => 'users#bulk_update_role'
      end
    end
    resources :ontologies do
      collection do
        post 'update_terms/:field', :to =>'ontologies#update_terms', :as=>'update_terms'
      end
    end
    resources :collection_highlights do
      collection do
        post 'set_highlight/:id', :to => 'collection_highlights#set_highlight'
      end
    end
    resources :gallery_highlights do
      collection do
        post 'set_highlight/:id', :to => 'gallery_highlights#set_highlight'
        post 'sort', :to => 'gallery_highlights#sort', :as=>'sort'
      end      
    end
  end
  
  # curator pages
  namespace :curator do
    resources :tasks do
      collection do
        post 'set_edit_mode/:id', :to => 'tasks#set_edit_mode'
        put 'item/:id/edit_metadata', :to => 'tasks#edit_metadata', :as => 'edit_metadata'
        put 'item/:id/set_top_priority_item', :to => 'tasks#set_top_priority_item', :as => 'set_top_priority_item'
        put 'item/:id/set_visibility', :to => 'tasks#set_visibility', :as => 'set_visibility'
        match 'annotations', :to => 'tasks#annotations', :as=>"annotations_table"        
        match 'edits', :to => 'tasks#edits', :as=>"edits_table"
        match 'flags', :to => 'tasks#flags', :as=>"flags_table"
        match 'favorites', :to => 'tasks#favorites', :as=>"favorites_table"
        match 'galleries', :to => 'tasks#galleries', :as=>"galleries_table"
      end
    end
    resources :help do
      collection do
        match ':action(/:id)(.:format)'       
      end
    end
  end
    
    
  match "*gibberish", :to => "application#routing_error"
    
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
  
end