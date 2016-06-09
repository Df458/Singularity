/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
using Valadate;

namespace Singularity.Tests
{
    [Test (name="UpdatePackage TestCases")]
    public class UpdatePackageTest : Framework.TestCase
    {
        static const string error_string = "An error has occurred";

        [Test (name="update_package_success")]
        public void testUpdatePackageSuccess()
        {
            Feed f = new Feed();
            Gee.List<Item?> i = new Gee.ArrayList<Item?>();
            UpdatePackage pkg = new UpdatePackage.success(f, i);
            assert_null(pkg.message);
            Assert.equals(f, pkg.feed);
            Assert.equals(i, pkg.items);
        }
        [Test (name="update_package_failure")]
        public void testUpdatePackageFailure()
        {
            Feed f = new Feed();
            UpdatePackage pkg = new UpdatePackage.failure(f, error_string);
            Assert.equals(f, pkg.feed);
            assert_null(pkg.items);
            Assert.equals(error_string, pkg.message, "wrong error message");
        }
    }
}
