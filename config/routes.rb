Revs::Application.routes.draw do

  root :to => "catalog#index"

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
    
  # version page
  match 'version', :to=>'about#show', :defaults => {:id=>'version'}, :as => 'version'

  match 'search', :to=> 'catalog#index', :as=>'search'
  
  # all collections pages helper route
  match 'collection', :to => 'collection#index', :as => 'all_collections'

  # ajax call from home page to get more images for the carousel
  match 'update_carousel', :to => 'catalog#update_carousel', :as => 'update_carousel'

  # in place edit ajax call
    
  # helper routes to we can have a friendly URL for items and collections
  match 'item/:id', :to=> 'catalog#show', :as =>'item'
  match 'collection/:id', :to=> 'catalog#show', :as =>'collection'
  
  # public user profile pages
  match 'user/:name/annotations', :to=>'user#annotations', :as=>'user_annotations', :via=>:get, :constraints => {:name => /\D+.+/} 
  match 'user/:name/flags', :to=>'user#flags', :as=>'user_flags', :via=>:get, :constraints => {:name => /\D+.+/} 
  match 'user/:id', :to=>'user#show', :as=>'user_profile_id', :via=>:get, :constraints => {:id => /\d+/} # all digits is assumed to be an ID
  match 'user/:name', :to=>'user#show_by_name', :as=>'user_profile_name', :via=>:get, :constraints => {:name => /\D+.+/} # any non digit followed by any other characters is assumed to be a name
  
  # Handles all About pages.
  match 'about', :to => 'about#show', :as => 'about_project', :defaults => {:id=>'project'} # no page specified, go to project page
  match 'contact', :to=> 'about#contact', :as=>'contact_us'
  match 'about/contact', :to=> 'about#contact' # specific contact us about page
  match 'about/:id', :to => 'about#show' # catch anything else and direct to show page with ID parameter of partial to show
  
  # term acceptance dialog
  match 'accept_terms', :to=> 'application#accept_terms', :as=> 'accept_terms', :via=>:post
  
  # bulk metadata editing
  post 'catalog', :to=>'catalog#index', :as=>'bulk_edit'
  
  resources :annotations do
    collection do
      get 'for_image/:id', :to => 'annotations#index_by_druid'
    end
  end
  
  resources :flags do
    collection do
      get 'for_image/:id', :to => 'flags#index_by_druid'
    end
  end
    
  # admin pages
  namespace :admin do
    resources :users
  end
  
  # curator pages
  namespace :curator do
    resources :tasks do
      collection do
        post 'set_edit_mode/:id', :to => 'tasks#set_edit_mode'
        put 'item/:id/edit_metadata', :to => 'tasks#edit_metadata', :as => 'edit_metadata'
        put 'item/:id/set_top_priority_item', :to => 'tasks#set_top_priority_item', :as => 'set_top_priority_item'
      end
    end
  end
    
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
