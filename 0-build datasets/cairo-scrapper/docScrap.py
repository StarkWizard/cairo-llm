import json
import os
import requests
import traceback
import re
from bs4 import BeautifulSoup
from markdownify import MarkdownConverter

def get_config (file):
    with open(file, 'r') as json_file:
        # Load JSON data into a Python dictionary
        config = json.load(json_file)
    return config


def print_error ():
    print(traceback.format_exc())


def get_soup (url): 
    response = requests.get(url)
    if (response.status_code != 200):
        raise Exception(f"Failed to load page {url}, status code: {response.status_code}")
    return BeautifulSoup(response.text, 'html.parser')


def get_internal_nav_links (site):
    soup = get_soup(site["url"])    
    links = soup.select_one(site["nav_selector"]).find_all('a', href=True)
    internal_links = [link['href'] for link in links if not link['href'].startswith("http") or link['href'].startswith(site["url"])]
    return internal_links
    

def create_folder (folder_path):
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)




def write_file (file_path, content):
    with open(file_path, 'w') as file:
        file.write(content)

def split_markdown_by_headings(markdown_text):
    headings = re.split(r'(^#+\s.*)', markdown_text, flags=re.MULTILINE)[1:]
    
    contents = []
    for i in range(0, len(headings), 2):
        heading_text = headings[i]
        content_text = headings[i + 1].strip() if i + 1 < len(headings) else ""
        contents.append(f"{heading_text}\n{content_text}")

    return contents

def crawl_site (root_path, site, internal_links):
    create_folder(os.path.join(root_path, site["output"]))
    for link in internal_links:
        print("Parsing...", os.path.join(site["url"], link))
        soup = get_soup(os.path.join(site["url"], link))
        main_html = soup.select_one(site["main_selector"])
        main_md = MarkdownConverter(**{ "heading_style": "ATX" }).convert_soup(main_html)
        divided_md_list = split_markdown_by_headings(main_md)
        
        for index, divided_md in enumerate(divided_md_list, start=1):
            filename = os.path.basename(link).rsplit('.', 1)[0] + "_" + str(index) + ".md"
            write_file(os.path.join(root_path, site["output"], filename), divided_md)



def main():
    root_path = os.path.dirname(os.path.realpath(__file__))
    site_list = get_config(os.path.join(root_path,'docScrap.config.json'))

    for site in site_list:
        try:
            internal_links = get_internal_nav_links(site)
            crawl_site(root_path, site, internal_links)
        except Exception as e:
            print_error(e)


if __name__ == "__main__":
    main()