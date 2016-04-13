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

#import "MovieTableViewController.h"
#import "MovieRecord.h"
#import "AlgoliaSearch-Swift.h"
#import "UIImageView+AFNetworking.h"
#import "MoviesSearch-Swift.h"

@interface MovieTableViewController ()

-(void) loadMore;

@end

@implementation MovieTableViewController {
    UISearchController *searchController;

    Client* client;
    Index *movieIndex;
    Query *query;
    
    NSMutableArray *movies;
    
    NSInteger searchId;
    NSInteger displayedSearchId;
    NSUInteger loadedPage;
    NSUInteger nbPages;
    
    UIImage *placeholder;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Search controller
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.dimsBackgroundDuringPresentation = NO;
    searchController.searchBar.delegate = self;
    
    // Add the search bar
    self.tableView.tableHeaderView = searchController.searchBar;
    self.definesPresentationContext = YES;
    [searchController.searchBar sizeToFit];
    
    // Algolia Search
    client = [[Client alloc] initWithAppID:@"latency" apiKey:@"dce4286c2833e8cf4b7b1f2d3fa1dbcb"];
    movieIndex = [client getIndex:@"movies"];
    
    query = [[Query alloc] init];
    query.hitsPerPage = [NSNumber numberWithInt:15];
    query.attributesToRetrieve = @[@"title", @"image", @"rating", @"year"];
    query.attributesToHighlight = @[@"title"];
    
    movies = [NSMutableArray array];
    searchId = 0;
    displayedSearchId = -1;
    loadedPage = 0;
    nbPages = 0;
    
    placeholder = [UIImage imageNamed:@"white"];
    
    // First load
    [self updateSearchResultsForSearchController:searchController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [self loadMore];
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
    query.query = self->searchController.searchBar.text;
    NSInteger curSearchId = searchId;
    
    [movieIndex search:query completionHandler:^(NSDictionary<NSString *,id>* result, NSError* error) {
        if (error != nil) {
            return;
        }
        if (curSearchId <= displayedSearchId) {
            return; // Newest query already displayed
        }
        
        displayedSearchId = curSearchId;
        loadedPage = 0; // Reset loaded page
        
        // Decode JSON
        NSArray *hits = result[@"hits"];
        nbPages = [result[@"nbPages"] integerValue];
        
        NSMutableArray *tmp = [NSMutableArray array];
        for (int i = 0; i < [hits count]; ++i) {
            [tmp addObject:[[MovieRecord alloc] init:hits[i]]];
        }
        
        // Reload view with the new data
        [movies removeAllObjects];
        [movies addObjectsFromArray:tmp];
        [self.tableView reloadData];
    }];
    
    ++searchId;
}

#pragma mark - Load more

- (void)loadMore {
    if (loadedPage + 1 >= nbPages) {
        return; // All pages already loaded
    }
    
    Query *nextQuery = [query copy];
    nextQuery.page = [NSNumber numberWithUnsignedInteger:loadedPage + 1];
    
    [movieIndex search:nextQuery completionHandler:^(NSDictionary<NSString *,id>* result, NSError* error) {
        if (error != nil) {
            return;
        }
        if (![nextQuery.query isEqualToString:query.query]) {
            return; // Query has changed
        }
        
        loadedPage = nextQuery.page.intValue;
        NSArray *hits = result[@"hits"];
        
        NSMutableArray *tmp = [NSMutableArray array];
        for (int i = 0; i < [hits count]; ++i) {
            [tmp addObject:[[MovieRecord alloc] init:hits[i]]];
        }
        
        // Reload view with the loaded data
        [movies addObjectsFromArray:tmp];
        [self.tableView reloadData];
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
