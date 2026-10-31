import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By

chrome_options = Options()
chrome_options.add_argument('--headless')
chrome_options.add_argument('--window-size=1400,900')

driver = webdriver.Chrome(options=chrome_options)

try:
    print("Testing 1: Home page on Supabase...")
    driver.get("http://127.0.0.1:5000/")
    time.sleep(2)
    driver.save_screenshot("C:/Users/rajde/.gemini/antigravity/brain/eb6389d7-0ab9-4479-b086-7efb6295a0e8/home_supabase_verified.png")
    print("Home page screenshot captured.")

    print("Testing 2: Destinations page on Supabase...")
    driver.get("http://127.0.0.1:5000/destinations/")
    time.sleep(2)
    driver.save_screenshot("C:/Users/rajde/.gemini/antigravity/brain/eb6389d7-0ab9-4479-b086-7efb6295a0e8/destinations_supabase_verified.png")
    print("Destinations page screenshot captured.")

    print("Testing 3: Packages page on Supabase...")
    driver.get("http://127.0.0.1:5000/packages/")
    time.sleep(2)
    driver.save_screenshot("C:/Users/rajde/.gemini/antigravity/brain/eb6389d7-0ab9-4479-b086-7efb6295a0e8/packages_supabase_verified.png")
    print("Packages page screenshot captured.")

    print("Testing 4: Login as john@example.com...")
    driver.get("http://127.0.0.1:5000/login")
    time.sleep(1.5)
    driver.find_element(By.NAME, "identifier").send_keys("john@example.com")
    driver.find_element(By.NAME, "password").send_keys("user123")
    btn = driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
    driver.execute_script("arguments[0].click();", btn)
    time.sleep(2.5)

    print(f"Current URL after login: {driver.current_url}")
    assert "/user/dashboard" in driver.current_url, f"Expected dashboard but got {driver.current_url}"
    driver.save_screenshot("C:/Users/rajde/.gemini/antigravity/brain/eb6389d7-0ab9-4479-b086-7efb6295a0e8/user_dashboard_supabase_verified.png")
    print("Dashboard screenshot captured successfully!")

    print("Testing 5: User wishlist on Supabase...")
    driver.get("http://127.0.0.1:5000/user/wishlist")
    time.sleep(2)
    driver.save_screenshot("C:/Users/rajde/.gemini/antigravity/brain/eb6389d7-0ab9-4479-b086-7efb6295a0e8/user_wishlist_supabase_verified.png")
    print("Wishlist screenshot captured successfully!")

    print("\nALL VERIFICATION TESTS COMPLETED SUCCESSFULLY!")

finally:
    driver.quit()
