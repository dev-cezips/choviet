import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = false
window.Stimulus = application

// Import all controllers
import DropdownController from "./dropdown_controller"
import GalleryController from "./gallery_controller"
import ImageSliderController from "./image_slider_controller"
import ImageUploadController from "./image_upload_controller"
import LightboxController from "./lightbox_controller"
import MessagesController from "./messages_controller"
import ModalController from "./modal_controller"
import PostFormController from "./post_form_controller"
import SearchExpandController from "./search_expand_controller"

// Register controllers
application.register("dropdown", DropdownController)
application.register("gallery", GalleryController)
application.register("image-slider", ImageSliderController)
application.register("image-upload", ImageUploadController)
application.register("lightbox", LightboxController)
application.register("messages", MessagesController)
application.register("modal", ModalController)
application.register("post-form", PostFormController)
application.register("search-expand", SearchExpandController)

export { application }
