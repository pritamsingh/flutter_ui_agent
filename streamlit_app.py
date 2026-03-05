"""
Flutter UI Agent - Streamlit UI
"""

import json
import os
import tempfile
import streamlit as st
from dotenv import load_dotenv
from flutter_ui_agent import FlutterUIAgent

load_dotenv(".env.example")

st.set_page_config(page_title="Blinkx UI Agent", layout="wide", page_icon="📱")

# --- Custom CSS ---
st.markdown("""
<style>
    .stMainBlockContainer { padding-top: 1rem; }
    .phone-frame {
        width: 390px; height: 844px; margin: 0 auto;
        border: 3px solid #333; border-radius: 40px;
        overflow: hidden; background: white;
        display: flex; flex-direction: column;
        box-shadow: 0 10px 40px rgba(0,0,0,0.3);
    }
    .phone-frame > .scaffold { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    .phone-frame > :not(.scaffold) { flex: 1; overflow-y: auto; }
    .appbar {
        padding: 12px 16px; display: flex; align-items: center;
        justify-content: center; min-height: 56px; flex-shrink: 0;
    }
    .appbar-title { font-size: 20px; font-weight: 600; }
    .bottom-nav { display: flex; border-top: 1px solid #e0e0e0; padding: 8px 0; flex-shrink: 0; }
    .bottom-nav-item {
        flex: 1; display: flex; flex-direction: column;
        align-items: center; gap: 4px; font-size: 12px; color: #9e9e9e;
    }
    .bottom-nav-item:first-child { color: #2196F3; }
    .bottom-nav-item .material-icon { font-size: 24px; }
    .scaffold-body { flex: 1; overflow-y: auto; }
    .w-column { display: flex; flex-direction: column; }
    .w-row { display: flex; flex-direction: row; align-items: center; }
    .w-row.space-between { justify-content: space-between; }
    .w-expanded { flex: 1; min-height: 0; overflow-y: auto; }
    .w-card { background: white; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.12); }
    .w-text { line-height: 1.4; }
    .w-textfield {
        border: 1px solid #ccc; border-radius: 4px;
        padding: 14px 12px; font-size: 14px; width: 100%;
    }
    .w-button {
        border: none; border-radius: 4px; padding: 14px 24px;
        color: white; font-size: 16px; cursor: pointer; text-align: center;
    }
    .w-icon { font-family: 'Material Icons'; font-size: 24px; }
    .w-listview { display: flex; flex-direction: column; }
    .w-center { display: flex; justify-content: center; align-items: center; }
</style>
<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
""", unsafe_allow_html=True)

# --- Session State ---
if "agent" not in st.session_state or not hasattr(st.session_state.get("agent"), "model_name"):
    api_key = os.getenv("GOOGLE_API_KEY", "")
    if api_key:
        st.session_state.agent = FlutterUIAgent(api_key)
    else:
        st.session_state.agent = None

if "schema" not in st.session_state:
    st.session_state.schema = None
if "generating" not in st.session_state:
    st.session_state.generating = False

# --- Header ---
st.title("Blinkx UI Agent")
st.caption("Generate Flutter UI from text descriptions with optional file attachments")

# --- API Key Check ---
if st.session_state.agent is None:
    api_key = st.text_input("Enter your Google API Key:", type="password")
    if api_key:
        st.session_state.agent = FlutterUIAgent(api_key)
        st.rerun()
    else:
        st.warning("Set GOOGLE_API_KEY in .env.example or enter it above.")
        st.stop()

agent: FlutterUIAgent = st.session_state.agent

# --- Screen Templates ---
SCREEN_TEMPLATES = {
    "Authentication": {
        "Login Screen": "Create a login screen with app logo at top, email and password text fields, a 'Forgot Password?' link, a primary login button, and a 'Sign up' link at the bottom",
        "Sign Up Screen": "Create a registration screen with name, email, password, and confirm password fields, terms checkbox, a 'Create Account' button, and 'Already have an account? Login' link",
        "OTP Verification": "Create an OTP verification screen with a title, subtitle showing the phone/email, 4 digit code input boxes in a row, a verify button, and a resend code timer link",
        "Forgot Password": "Create a forgot password screen with an illustration/icon, instructional text, an email input field, and a 'Send Reset Link' button",
        "Two-Factor Auth": "Create a two-factor authentication screen with a security icon, instruction text, a 6-digit code input, verify button, and backup code link",
    },
    "Dashboard": {
        "Analytics Dashboard": "Create an analytics dashboard with a greeting header, 4 stat cards in a 2x2 grid (revenue, users, orders, growth) with icons and percentages, and a recent activity list below",
        "Admin Dashboard": "Create an admin dashboard with a sidebar navigation, top stats bar, a data table with user records, and action buttons for edit/delete",
        "Home Feed": "Create a home feed screen with a top app bar with search and notification icons, a horizontal category scroll, and a vertical list of content cards with images and titles",
        "Overview Dashboard": "Create a simple overview dashboard with a welcome banner, 3 summary cards in a row, a line chart placeholder, and a recent transactions list",
    },
    "Profile": {
        "User Profile": "Create a user profile screen with a cover photo, circular avatar, user name and bio, stats row (posts, followers, following), an edit profile button, and a tab bar for posts/media/likes",
        "Profile Settings": "Create a profile settings screen with an editable avatar, form fields for name, email, phone, bio, and a save changes button at the bottom",
        "Public Profile": "Create a public profile card with avatar, name, title/role, location, a brief bio, social media icon links, and a follow/message button row",
        "Account Info": "Create an account information screen with sections for personal info, contact details, and linked accounts, each with edit icons",
    },
    "Chat & Messaging": {
        "Chat List": "Create a chat list screen with a search bar at top, and a scrollable list of conversations showing avatar, name, last message preview, timestamp, and unread badge",
        "Chat Conversation": "Create a chat conversation screen with an app bar showing contact name and avatar, message bubbles (sent in blue on right, received in grey on left) with timestamps, and a bottom input bar with attach and send buttons",
        "Group Chat": "Create a group chat screen with group name and member count in app bar, message bubbles with sender names in different colors, and a bottom compose bar",
        "Chat Empty State": "Create an empty chat state screen with a large illustration, 'No messages yet' heading, descriptive subtext, and a 'Start Conversation' button",
    },
    "E-Commerce": {
        "Product List": "Create a product listing screen with a search/filter bar, a grid of product cards each showing product image, name, price, rating stars, and an add-to-cart icon button",
        "Product Detail": "Create a product detail screen with a large product image carousel, product title, price, rating, description text, size/color selectors, quantity picker, and an 'Add to Cart' button",
        "Shopping Cart": "Create a shopping cart screen with a list of cart items (image, title, price, quantity stepper), a promo code input, order summary section with subtotal/shipping/total, and a checkout button",
        "Checkout": "Create a checkout screen with steps indicator (shipping, payment, review), shipping address form, payment method selection with card icons, order summary, and a 'Place Order' button",
        "Order History": "Create an order history screen with a list of past orders showing order number, date, status badge (delivered/shipped/processing), item count, total, and a 'View Details' button",
    },
    "Settings": {
        "App Settings": "Create a settings screen with grouped sections: Account (profile, password, privacy), Preferences (notifications, language, theme toggle), Support (help, feedback, about), and a logout button at bottom",
        "Notification Settings": "Create a notification settings screen with toggle switches grouped by category: Messages, Updates, Promotions, Reminders, with description text under each toggle",
        "Privacy Settings": "Create a privacy settings screen with toggles for profile visibility, online status, read receipts, data sharing, and a 'Delete Account' danger button at the bottom",
        "Theme/Appearance": "Create an appearance settings screen with light/dark/system theme selector cards, accent color palette circles, font size slider, and a preview section",
    },
    "Social & Content": {
        "Social Feed": "Create a social media feed with a stories row at top (circular avatars with names), and a vertical feed of posts with user header, image, like/comment/share action row, and caption",
        "Photo Gallery": "Create a photo gallery screen with a grid of images (3 columns), a floating action button to add photos, and a top tab bar for All/Photos/Videos/Albums",
        "News/Blog List": "Create a news listing screen with a featured article card at top (large image, headline, source), followed by a list of article rows with thumbnail, title, source, and time ago",
        "Video Player": "Create a video player screen with a 16:9 video placeholder with play button overlay, video title, channel info row with subscribe button, like/dislike/share actions, and a comments section",
    },
    "Forms & Input": {
        "Contact Form": "Create a contact form screen with name, email, subject, and message (multiline) fields, a file attachment button, and a submit button",
        "Survey/Quiz": "Create a survey screen with a progress bar at top, question number and text, radio button options, and next/previous navigation buttons at bottom",
        "Multi-Step Form": "Create a multi-step form with a step indicator (3 steps), current step form fields, and back/next buttons at the bottom",
        "Search & Filter": "Create a search screen with a search bar, recent searches chips, filter dropdowns for category/price/rating, and a results count with sort option",
    },
    "Onboarding": {
        "Welcome Carousel": "Create an onboarding carousel with a large illustration, headline, description text, dot indicators for 3 pages, a 'Next' button, and a 'Skip' link",
        "Feature Tour": "Create a feature tour screen with an app screenshot, a highlighted feature callout box, step indicator (1 of 4), and next/skip buttons",
        "Permissions Request": "Create a permissions request screen with an icon, title explaining the permission (e.g., Location), benefit description, 'Allow' primary button, and 'Maybe Later' text button",
        "Get Started": "Create a get started screen with the app logo, tagline, a 'Sign in with Google' button, a 'Sign in with Apple' button, an email sign in button, and terms text at bottom",
    },
    "Utility Screens": {
        "Error / 404": "Create a 404 error screen with a large error illustration, '404' heading, 'Page not found' subtitle, descriptive text, and a 'Go Home' button",
        "Empty State": "Create an empty state screen with a placeholder illustration, 'Nothing here yet' heading, a suggestion subtitle, and a primary action button",
        "Loading / Skeleton": "Create a loading skeleton screen mimicking a content list with animated shimmer placeholder rectangles for avatar, title lines, and image cards",
        "Success Confirmation": "Create a success confirmation screen with a green checkmark animation circle, 'Payment Successful' heading, amount and transaction details, and a 'Done' button",
    },
    "Finance & Payments": {
        "Wallet Screen": "Create a digital wallet screen with a balance card showing amount and currency, quick action buttons (send, receive, pay, top-up), and a transaction history list",
        "Payment Screen": "Create a payment screen with amount input, recipient info, payment method selector (cards list), and a 'Pay Now' button with total",
        "Transaction Detail": "Create a transaction detail screen with status badge, amount, date/time, from/to info, transaction ID, category, and a receipt download button",
        "Budget Tracker": "Create a budget tracker with monthly budget progress bar, spending by category (food, transport, entertainment) with progress bars and amounts, and a recent expenses list",
    },
    "Maps & Location": {
        "Map View": "Create a map screen with a full-screen map placeholder, a bottom sheet with a search bar and nearby location cards, and a floating 'My Location' button",
        "Location List": "Create a nearby locations list with a search bar, distance filter chips, and a list of place cards with image, name, rating, distance, and directions button",
        "Ride Booking": "Create a ride booking screen with pickup/destination input fields, a map section, vehicle type selector cards (economy, premium, SUV) with prices, and a 'Book Ride' button",
    },
    "Media & Entertainment": {
        "Music Player": "Create a music player screen with album art, song title and artist, a progress slider with timestamps, playback controls (shuffle, previous, play/pause, next, repeat), and a volume slider",
        "Podcast List": "Create a podcast listing screen with featured podcast banner, category filter chips, and a list of podcast cards with cover art, title, author, duration, and play button",
        "Streaming Home": "Create a streaming app home screen with a hero banner for featured content, horizontal scroll sections for 'Continue Watching', 'Trending', and 'New Releases' with poster thumbnails",
    },
}

# --- Sidebar: Templates & Attachment ---
with st.sidebar:
    st.header("Screen Templates")

    categories = list(SCREEN_TEMPLATES.keys())
    selected_category = st.selectbox("Select screen category:", ["-- Custom Description --"] + categories)

    selected_template_desc = ""
    if selected_category != "-- Custom Description --":
        templates = SCREEN_TEMPLATES[selected_category]
        template_names = list(templates.keys())
        selected_template = st.selectbox("Select a template:", template_names)
        selected_template_desc = templates[selected_template]
        st.info(f"**{selected_template}**\n\n{selected_template_desc}")

    st.divider()
    st.header("Model")
    selected_model = st.selectbox(
        "Gemini model:",
        FlutterUIAgent.AVAILABLE_MODELS,
        index=0,
        help="gemini-2.0-flash has higher free-tier limits. Switch if you hit rate limits.",
    )
    current_model = getattr(agent, "model_name", None) if agent else None
    if current_model != selected_model and agent is not None:
        agent.set_model(selected_model)
        st.success(f"Switched to {selected_model}")

    st.divider()
    st.header("Attachment")
    uploaded_file = st.file_uploader(
        "Upload a reference file",
        type=["png", "jpg", "jpeg", "webp", "gif", "bmp", "html", "css", "json", "txt", "xml", "svg"],
        help="Attach an image or HTML/CSS/JSON file as design reference",
    )
    if uploaded_file:
        st.success(f"Attached: {uploaded_file.name}")
        if uploaded_file.type and uploaded_file.type.startswith("image/"):
            st.image(uploaded_file, width=250)

# --- Main Input ---
default_desc = selected_template_desc
description = st.text_area("Describe the UI you want to generate:", value=default_desc, height=100,
                           placeholder="e.g., Create a modern dashboard with cards showing stats...")

col_gen, col_clear = st.columns([1, 4])
with col_gen:
    generate_btn = st.button("Generate UI", type="primary", use_container_width=True)
with col_clear:
    if st.session_state.schema:
        if st.button("Clear"):
            st.session_state.schema = None
            st.rerun()

# --- Generate ---
if generate_btn and description.strip():
    attachment_path = None
    tmp_file = None

    # Save uploaded file to temp location
    if uploaded_file:
        suffix = os.path.splitext(uploaded_file.name)[1]
        tmp_file = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
        tmp_file.write(uploaded_file.getvalue())
        tmp_file.close()
        attachment_path = tmp_file.name

    status_placeholder = st.empty()
    with st.spinner("Generating UI... This may take a moment for large attachments."):
        try:
            def update_status(msg):
                status_placeholder.warning(msg)

            schema = agent.generate_ui(
                description.strip(),
                attachment_path=attachment_path,
                status_callback=update_status,
            )
            st.session_state.schema = schema
            status_placeholder.empty()
        except Exception as e:
            status_placeholder.empty()
            st.error(f"Error: {e}")
        finally:
            if tmp_file and os.path.exists(tmp_file.name):
                os.unlink(tmp_file.name)

    if st.session_state.schema:
        st.rerun()

elif generate_btn:
    st.warning("Please enter a UI description.")

# --- Display Results ---
if st.session_state.schema:
    schema = st.session_state.schema

    tab_preview, tab_json, tab_dart = st.tabs(["Preview", "JSON Schema", "Flutter Code"])

    with tab_preview:
        preview_html = agent._schema_to_html(schema)
        full_html = f'<div class="phone-frame">{preview_html}</div>'
        st.markdown(full_html, unsafe_allow_html=True)

    with tab_json:
        json_str = json.dumps(schema, indent=2)
        st.code(json_str, language="json")

        col_dl, col_copy = st.columns(2)
        with col_dl:
            st.download_button(
                "Download JSON",
                data=json_str,
                file_name="flutter_ui_schema.json",
                mime="application/json",
            )
        with col_copy:
            # Export to project assets
            if st.button("Export to assets/ui_schema.json"):
                assets_dir = os.path.join(os.path.dirname(__file__), "assets")
                os.makedirs(assets_dir, exist_ok=True)
                out_path = os.path.join(assets_dir, "ui_schema.json")
                with open(out_path, "w") as f:
                    json.dump(schema, f, indent=2)
                st.success(f"Exported to {out_path}")

    with tab_dart:
        dart_code = agent.generate_flutter_code(schema)
        st.code(dart_code, language="dart")
        st.download_button(
            "Download Dart",
            data=dart_code,
            file_name="generated_ui.dart",
            mime="text/plain",
        )
