import json
import os
import requests
import traceback
import argparse
from fnmatch import fnmatch
from bs4 import BeautifulSoup
import html2text

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

def normalize_link (site, link):
    if not link.startswith("http"):
        return os.path.join(site["url"], link)
    return link


def get_internal_nav_links (site):
    soup = get_soup(site["url"])    
    links = soup.select_one(site.get("nav_selector") or "nav").find_all('a', href=True)
    internal_links = [link['href'] for link in links if not link.get('href').startswith("http") or link.get('href').startswith(site["url"])]
    exclude = site.get("exclude") or []

    normalized_internal_links = [normalize_link(site, link) for link in internal_links]
    normalized_exclude = [normalize_link(site, link) for link in exclude]

    final_links = []
    for link in normalized_internal_links:
        if any(fnmatch(link, pattern) for pattern in normalized_exclude):
            print(f"Exclude: {link}")
        else:
            final_links.append(link)

    return final_links
    

def create_folder (folder_path):
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)


def write_file (file_path, content):
    with open(file_path, 'w') as file:
        file.write(content)

def copy_bs4_tag(tag):
    return BeautifulSoup(str(tag), 'html.parser').contents[0]

def split_soup_by_headings(soup):
    res = []
    el = soup[0]
    new_soup = BeautifulSoup("", 'html.parser')
    new_soup.append(copy_bs4_tag(el))

    for idx, tag in enumerate(el.next_siblings):
        if tag.name and tag.name.startswith('h'):
            res.append(new_soup)
            new_soup = BeautifulSoup("", 'html.parser')
        new_soup.append(copy_bs4_tag(tag))

        if idx - 2 == len(soup) and not (tag.name and tag.name.startswith('h')):
            res.append(new_soup)

    return res

def convert_soup_to_markdown(soup):
    mdConverter = html2text.HTML2Text()
    mdConverter.ignore_links = False
    return mdConverter.handle(str(soup))


def convert_soup_to_txt(soup):
    res = ""
    for string in soup.strings:
        res += string
    return res


def crawl_site (root_path, site, internal_links, extension):
    create_folder(os.path.join(root_path, site["output"]))
    for link in internal_links:
        print("Parsing...", link)
        soup = get_soup(link)
        main_soup = soup.select(site["main_selector"] + " *")
        divided_soup = split_soup_by_headings(main_soup)
        
        for index, source in enumerate(divided_soup, start=1):
            filename = os.path.basename(link).rsplit('.', 1)[0] + "_" + str(index) + "." + extension
            if extension == "md":
                content = convert_soup_to_markdown(source)
            elif extension == 'txt':
                content = convert_soup_to_txt(source)
            write_file(os.path.join(root_path, site["output"], filename), content)


def main():
    """
    It will read the config file and crawl the site

    Example config file:
    [
        {
            "url": https://example.com,
            "output": "scrapped/path-to-save",
            "nav_selector": "nav",
            "main_selector": "main",
            "exclude": [
                "https://example.com/path.html", 
                "https://example.com/**/*.html" // Support glob pattern
            ]
        }, 
    ]
    """
    parser = argparse.ArgumentParser(description="docScrap: Documentation Scrapper CLI Tool")
    parser.add_argument("-ext", "--extension", help="Output file extension", choices=["md", "txt"])
    args = parser.parse_args()
    extension = args.extension or "md"

    root_path = os.path.dirname(os.path.realpath(__file__))
    site_list = get_config(os.path.join(root_path,'docScrap.config.json'))

    for site in site_list:
        try:
            internal_links = get_internal_nav_links(site)
            crawl_site(root_path, site, internal_links, extension)
        except Exception as e:
            print_error(e)


if __name__ == "__main__":
    main()