//
//  Copyright (c) 2015 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@import AFNetworking;
@import AlgoliaSearch;
@import InstantSearchCore;

#import "MovieTableViewController.h"
#import "MovieRecord.h"
#import "MoviesSearch-Swift.h" // for `UILabel(Highlighting)`


@interface MovieTableViewController () <SearcherDelegate>

@end

@implementation MovieTableViewController {
    UISearchController *searchController;

    Client* client;
    Index *movieIndex;
    Searcher *movieSearcher;
    
    NSMutableArray *movies;
    
    UIImage *placeholder;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    placeholder = [UIImage imageNamed:@"white"];

    // Search controller
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.dimsBackgroundDuringPresentation = NO;
    searchController.searchBar.delegate = self;
    
    // Add the search bar
    self.tableView.tableHeaderView = searchController.searchBar;
    self.definesPresentationContext = YES;
    [searchController.searchBar sizeToFit];
    
    // Initialize Algolia Search.
    client = [[Client alloc] initWithAppID:@"latency" apiKey:@"dce4286c2833e8cf4b7b1f2d3fa1dbcb"];
    movieIndex = [client indexWithName:@"movies"];
    movieSearcher = [[Searcher alloc] initWithIndex:movieIndex];
    movieSearcher.delegate = self;
    
    // Configure default search criteria.
    movieSearcher.params.hitsPerPage = @15;
    movieSearcher.params.attributesToRetrieve = @[@"title", @"image", @"rating", @"year"];
    movieSearcher.params.attributesToHighlight = @[@"title"];
    
    // Reset data.
    movies = [NSMutableArray array];

    // First load
    [self updateSearchResultsForSearchController:searchController];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [movies count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"movieCell" forIndexPath:indexPath];
    
    if (indexPath.row + 5 >= [movies count]) {
        [movieSearcher loadMore];
    }
    
    MovieRecord *movie = movies[indexPath.row];
    cell.textLabel.highlightedTextColor = [UIColor colorWithRed:1 green:1 blue:0.898 alpha:1];
    cell.textLabel.highlightedText = movie.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", movie.year];
    
    // Avoid loading image that we don't need anymore
    [cell.imageView cancelImageDownloadTask];
    // Load the image and display another image during the loading
    [cell.imageView setImageWithURL:[NSURL URLWithString:movie.image] placeholderImage:placeholder];
    
    return cell;
}

#pragma mark - Search bar

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    movieSearcher.params.query = self->searchController.searchBar.text;
    [movieSearcher search];
}

#pragma mark - SearcherDelegate

- (void)searcher:(Searcher *)searcher didReceiveResults:(SearchResults *)results error:(NSError *)error forParams:(SearchParameters *)params {
    if (error != nil) {
        return;
    }
    
    // Decode JSON.
    NSArray *hits = [results hits];
    NSMutableArray *tmp = [NSMutableArray array];
    for (int i = 0; i < [hits count]; ++i) {
        [tmp addObject:[[MovieRecord alloc] init:hits[i]]];
    }
    
    // Reload view with the new data.
    if (results.page == 0) {
        [movies removeAllObjects];
    }
    [movies addObjectsFromArray:tmp];
    [self.tableView reloadData];
    
    // Scroll to top if not a "load more".
    if (results.page == 0) {
        self.tableView.contentOffset = CGPointZero;
    }
}

@end
