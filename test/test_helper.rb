ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
    
    # Disable image validation for marketplace posts in tests
    setup do
      Post.class_eval do
        def minimum_images_for_marketplace
          # Skip validation in test environment
        end
      end
    end

    # Add more helper methods to be used by all tests here...
    
    # Helper to sign in a user
    def sign_in(user)
      post user_session_path, params: {
        user: {
          email: user.email,
          password: 'password123'
        }
      }
    end
    
    # Helper to create a user with default attributes
    def create_user(attributes = {})
      default_attributes = {
        email: "test#{SecureRandom.hex(4)}@example.com",
        password: 'password123',
        name: "Test User",
        locale: 'vi'
      }
      User.create!(default_attributes.merge(attributes))
    end
    
    # Helper to create a post with default attributes
    def create_post(user, attributes = {})
      default_attributes = {
        title: "Test Post",
        content: "Test content",
        post_type: 'marketplace',
        status: 'active'
      }
      post = user.posts.build(default_attributes.merge(attributes))
      post.save(validate: false)
      
      # Create product if marketplace post
      if post.marketplace? && !attributes[:skip_product]
        post.create_product!(
          name: attributes[:product_name] || post.title,
          price: attributes[:price] || 100000,
          condition: attributes[:condition] || 'good'
        )
      end
      
      # Attach dummy images for marketplace posts
      if post.marketplace? && !attributes[:skip_images]
        5.times do |i|
          post.images.attach(
            io: StringIO.new('dummy image data'),
            filename: "test_image_#{i}.jpg",
            content_type: 'image/jpeg'
          )
        end
      end
      
      post
    end
    
    # Helper to create a marketplace post with product (convenience method)
    def create_marketplace_post(user, attributes = {})
      post = user.posts.build(
        title: attributes[:title] || "Test Product",
        content: attributes[:content] || "Test description", 
        post_type: "marketplace",
        status: "active"
      )
      post.save(validate: false)
      
      post.create_product!(
        name: attributes[:product_name] || post.title,
        price: attributes[:price] || 100000,
        condition: attributes[:condition] || "good"
      )
      
      post
    end
    
    # Helper to create a chat room
    def create_chat_room(post, buyer)
      ChatRoom.create!(
        post: post,
        buyer: buyer,
        seller: post.user
      )
    end
    
    # Helper to create a message
    def create_message(chat_room, sender, content)
      Message.create!(
        chat_room: chat_room,
        sender: sender,
        content_raw: content,
        content_translated: content,
        src_lang: sender.locale
      )
    end
    
    # Helper to create a review
    def create_review(chat_room, reviewer, reviewee, rating, comment = nil)
      Review.create!(
        chat_room: chat_room,
        reviewer: reviewer,
        reviewee: reviewee,
        rating: rating,
        comment: comment,
        visibility: true
      )
    end
  end
end

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  # include Capybara::DSL if defined?(Capybara)
  
  # Add devise test helpers
  include Devise::Test::IntegrationHelpers if defined?(Devise)
end