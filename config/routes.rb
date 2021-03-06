Kmedia::Application.routes.draw do

  scope '/(:locale)', constraints: {locale: /en|he|ru|es|de/} do

    resources :searches
    resources :feeds, only: [:index] do
      collection do
        get 'wsxml'
        get 'rss_video'
        get 'google_mapindex'
      end
    end

    resources :ui, only: [:index, :show] do
      collection do
        get 'homepage'
      end
      member do
        get 'homepage_show'
      end
    end

    resources :comments, only: :create

    root to: 'ui#homepage'

    mount Ckeditor::Engine => '/ckeditor'

    devise_for :users
    devise_scope :user do
      get '/login' => 'devise/sessions#new'
    end
    resources :users

    namespace(:admin) do
      root to: 'searches#index'

      resources :virtual_lessons do
        collection do
          get 'combine'
        end
      end
      resources :file_types
      resources :comments, only: [:index, :destroy]

      resources :censorship, only: [:index, :show] do
        member do
          post 'clear'
          post 'disable'
        end
      end

      resources :lessons do
        member do
          get 'parse_lesson_name'
          get 'edit_long_descr'
          get 'edit_transcript'
          get 'mark_for_merge'
          put 'update_long_descr'
          put 'update_transcript'
          get 'merge_get_list'
          post 'merge'
          post 'send_to_censor'
        end
        collection do
          get 'parse_new_lesson_name'
          get 'get_update'
          post 'add_update'
          get 'combine'
        end
        resources :catalogs do
          member do
            get 'batch'
          end
        end
      end

      resources :selected_catalogs, only: [:index, :new, :edit, :update] do
        collection do
          post 'set_selected'
          get 'autocomplete'
        end
        member do
          delete 'unset_selected'
        end
      end

      resources :file_assets
      resources :catalogs do
        collection do
          get :manage
          get :move_prepare
          get :move

          # required for Sortable GUI server side actions
          post :rebuild
        end
      end
      resources :departments
      resources :users do
        member do
          get :become
        end
      end
      resources :lessondesc_patterns
      resources :searches
      resources :dictionaries do
        collection do
          get :existing_suids
          get 'labels/existing_suids', to: 'labels#existing_suids'
          get 'labels/assignable', to: 'labels#assignable'
        end
        resources :labels
      end

    # using "post" method for the api calls because "get"  is being redirected to sign in page
    namespace :api do
      resources :tokens, only: [:create, :destroy]
      resources :api, only: [] do
        collection do
          post :register_file, :get_file_servers
          post :content_types, :file_types, :catalogs, :languages, :file_ids, :files, :patterns, :morning_lesson_files
          get :patterns
        end
        member do
        end
      end
    end
    end
  end
end
