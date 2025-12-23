Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :tik_tok_shops, only: [] do
        member do
          get :product_analytics
        end
      end
    end
  end
end

