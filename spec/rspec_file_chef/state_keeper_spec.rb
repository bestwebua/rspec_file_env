module RspecFileChef
  RSpec.describe TestClass do
    let(:test_examples_path)    { File.expand_path("../support/test_examples", __dir__) }
    let(:test_dir)              { "#{test_examples_path}/test_dir" }
    let(:tmp_dir)               { "#{test_examples_path}/temp_dir" }
    let(:target_dir)            { "#{test_examples_path}/target_dir" }
    let(:target_files_examples) { "#{test_examples_path}/target_files_examples" }
    let(:copy_target_files)     { FileUtils.cp_r("#{target_files_examples}/.", target_dir) }
    let(:clear_target_dir)      { FileUtils.rm_r(Dir.glob("#{target_dir}/*")) }
    let(:clear_tmp_dir)         { FileUtils.rm_r(Dir.glob("#{tmp_dir}/*")) }
    let(:set_tmp_dir)           { allow(subject).to receive(:tmp_dir).and_return(tmp_dir) }
    let(:set_test_dir)          { allow(subject).to receive(:test_dir).and_return(test_dir) }
    let(:regex_pattern)         { subject.send(:file_pattern) }
    let(:target_dir_files)      { get_dir_files(target_dir) }

    let(:test_tracking_files) do
      [
       "#{test_examples_path}/target_dir/target_file_1",
       "#{test_examples_path}/target_dir/real_dir/target_file_2",
       "#{test_examples_path}/target_dir/virtual_dir_1/virtual_dir_2/target_file_3"
      ]
    end

    let(:create_path_table) do
      copy_target_files
      allow(subject).to receive(:tracking_files).and_return(test_tracking_files)
      subject.send(:create_path_table)
    end

    def get_dir_files(location)
      target_dir_entries = Dir.glob("#{location}/**/*")
      file_names = target_dir_entries.map do |entry|
        entry[/#{regex_pattern}/,2] if File.file?(entry)
      end
      file_names.compact
    end

    def target_file_data(index)
      file_pattern = subject.send(:file_pattern)
      file_path = subject.tracking_files[index]
      file_name = file_path[/#{file_pattern}/,2]
      file_dir = file_path[/#{file_pattern}/,1]
      dir_exist = File.exist?(file_dir)
      level_depth = subject.send(:existing_level_depth, file_dir)
      [file_name, [file_path, file_dir, dir_exist, level_depth]]
    end

    def nonexistent_dir?(path)
      subject.path_table.values.map { |item| [item[1], item[2]] }.to_h[path]
    end

    describe '#tracking_files' do
      specify { expect(subject.tracking_files).to be_an_instance_of(Array) }
    end

    describe '#path_table' do
      specify { expect(subject.path_table).to be_an_instance_of(Hash) }
    end

    describe '#file_pattern' do
      shared_examples(:regex_parse) do
        specify { expect(string[/#{regex_pattern}/,1]).to eq(first_group) }
        specify { expect(string[/#{regex_pattern}/,2]).to eq(second_group) }
      end

      context 'returns Regex object' do
        specify { expect(regex_pattern).to be_an_instance_of(Regexp) }
      end
      
      context 'test string 1' do
        let(:string) { '/path/file' }
        let(:first_group) { '/path' }
        let(:second_group) { 'file' }
        it_behaves_like(:regex_parse)
      end

      context 'test string 2' do
        let(:string) { '/path/path/file' }
        let(:first_group) { '/path/path' }
        let(:second_group) { 'file' }
        it_behaves_like(:regex_parse)
      end

      context 'test string 3' do
        let(:string) { '/path/file.extension' }
        let(:first_group) { '/path' }
        let(:second_group) { 'file.extension' }
        it_behaves_like(:regex_parse)
      end

      context 'test string 4' do
        let(:string) { '/path/.file' }
        let(:first_group) { '/path' }
        let(:second_group) { '.file' }
        it_behaves_like(:regex_parse)
      end

      context 'test string 5' do
        let(:string) { '/path' }
        let(:first_group) { nil }
        let(:second_group) { nil }
        it_behaves_like(:regex_parse)
      end

      context 'test string 6' do
        let(:string) { 'file' }
        let(:first_group) { nil }
        let(:second_group) { nil }
        it_behaves_like(:regex_parse)
      end

      context 'test string 7' do
        let(:string) { 'path/file.extension' }
        let(:first_group) { 'path' }
        let(:second_group) { 'file.extension' }
        it_behaves_like(:regex_parse)
      end

      context 'test string 8' do
        let(:string) { '/path/file/' }
        let(:first_group) { nil }
        let(:second_group) { nil }
        it_behaves_like(:regex_parse)
      end

      context 'test string 9' do
        let(:string) { '/path/file./' }
        let(:first_group) { nil }
        let(:second_group) { nil }
        it_behaves_like(:regex_parse)
      end
    end

    describe '#tracking_files_not_uniq?' do
      describe 'files not unique' do
        before { allow(subject).to receive(:tracking_files).and_return([1,2,1]) }
        specify { expect(subject.send(:tracking_files_not_uniq?)).to be(true) }
      end

      describe 'files unique' do
        before { allow(subject).to receive(:tracking_files).and_return([1,2,3]) }
        specify { expect(subject.send(:tracking_files_not_uniq?)).to be(false) }
      end
    end

    describe '#check_tracking_files' do
      before { allow(subject).to receive(:tracking_files_not_uniq?).and_return(true) }
      specify { expect{subject.send(:check_tracking_files)}.to raise_error(RuntimeError, 'Tracking files not unique!') }
    end

    describe '#discover_path_depth' do
      specify { expect{subject.send(:discover_path_depth)}.to raise_error(ArgumentError) }

      specify do
        expect{subject.send(:discover_path_depth, 'path_without_slash')}.to raise_error(RuntimeError, 'Wrong path!')
      end

      specify { expect(subject.send(:discover_path_depth, '/path')).to be_an_instance_of(Array) }
      
      describe 'scenario' do
        context 'one level path' do
          let(:path) { '/path' }
          specify { expect(subject.send(:discover_path_depth, path).size).to eq(1) }
          specify { expect(subject.send(:discover_path_depth, path).first).to eq(path) }
        end

        context 'two level path' do
          let(:path) { '/path/path' }
          let(:discover_path_depth) { subject.send(:discover_path_depth, path) }
          specify { expect(discover_path_depth.size).to eq(2) }
          specify { expect(discover_path_depth.first).to eq(path) }
          specify { expect(discover_path_depth.last).to eq('/path') }
        end

        context 'access by index' do
          specify { expect(subject.send(:discover_path_depth, '/other_path')[0]).to eq('/other_path') }
        end
      end
    end

    describe '#existing_level_depth' do
      before { copy_target_files }
      after { clear_target_dir }
      specify { expect{subject.send(:existing_level_depth)}.to raise_error(ArgumentError) }
      specify { expect(subject.send(:existing_level_depth, "#{target_dir}/real_dir")).to eq(0) }
      specify { expect(subject.send(:existing_level_depth, "#{target_dir}/virtual_dir")).to eq(1) }
    end

    describe '#create_path_table' do
      before { create_path_table }
      after { clear_target_dir }

      shared_examples(:file_in_path_table) do
        specify do
          expect(subject.path_table.to_a[index]).to eq(target_file_data(index))
        end
      end

      context 'path_table should be created' do
        specify { expect(subject.path_table).not_to be_empty }
      end

      describe 'scenario' do
        context 'file path exist' do
          context 'target file 1' do
            let(:index) { 0 }
            it_behaves_like(:file_in_path_table)
          end
        end

        context 'file path not exist' do
          context 'target file 2' do
            let(:index) { 1 }
            it_behaves_like(:file_in_path_table)
          end
        end
      end
    end

    describe '#test_files' do
      before do
        create_path_table
        allow(subject).to receive(:test_dir)
      end
      after { clear_target_dir }
      specify { expect(subject.test_files).to be_an_instance_of(Array) }
      specify { expect(subject.test_files).to eq(%w[/target_file_1 /target_file_2 /target_file_3]) }
    end

    describe '#move_to_tmp_dir' do
      before do
        create_path_table
        set_tmp_dir
        subject.send(:move_to_tmp_dir)
      end

      after { clear_target_dir; clear_tmp_dir }

      let(:target_file) { 'target_file_1' }

      describe 'scenario' do
        context 'temp dir' do
          specify { expect(Dir.entries(tmp_dir)).to include(target_file) }
        end

        context 'target dir' do
          specify { expect(Dir.entries(target_dir)).not_to include(target_file) }
        end
      end
    end

    describe '#create_nonexistent_dirs' do
      before do
        create_path_table
        subject.send(:create_nonexistent_dirs)
      end

      after { clear_target_dir }

      
      describe 'scenario' do
        describe 'real dir' do
          context 'should not create dir' do
            before { FileUtils.rm_r("#{target_dir}/real_dir") }
            specify { expect(Dir.entries(target_dir)).not_to include('real_dir') }
          end
        end

        describe 'virtual dir' do
          context 'should create dir recursively' do
            let(:virtual_dir) { 'virtual_dir_1' }

            context 'first level' do
              specify do
                expect(Dir.entries(target_dir)).to include(virtual_dir)
              end
            end

            context 'second level' do
              specify do
                expect(Dir.entries("#{target_dir}/#{virtual_dir}")).to include('virtual_dir_2')
              end
            end
          end
        end
      end
    end

    describe '#same_file_path' do
      before { create_path_table }
      after { clear_target_dir }

      let(:tracked_file_path) { subject.path_table['target_file_1'][1] }

      describe 'scenario' do
        context 'test file with existen name like key in path table' do
          specify do
            expect(subject.send(:same_file_path, '/path/target_file_1')).to eq(tracked_file_path)
          end
        end

        context 'test file with non existen name like key in path table' do
          specify do
            expect(subject.send(:same_file_path, '/path/target_file')).to eq(nil)
          end
        end
      end
    end

    describe '#copy_from_test_dir' do
      before do
        create_path_table
        set_tmp_dir
        subject.send(:move_to_tmp_dir)
        subject.send(:create_nonexistent_dirs)
        set_test_dir
        subject.send(:copy_from_test_dir)
      end

      after { clear_target_dir; clear_tmp_dir }

      describe 'scenario' do
        context 'file in test dir' do
          context 'has same file in path table' do
            it 'file in target dir: zero level' do
              expect(target_dir_files).to include('target_file_1')
            end

            it 'file in target dir: first level' do
              expect(target_dir_files).to include('target_file_2')
            end

            it 'file in target dir: second level' do
              expect(target_dir_files).to include('target_file_3')
            end
          end

          context 'has no same file in path table' do
            specify { expect(target_dir_files).not_to include('target_file_4') }
          end
        end
      end
    end

    describe '#delete_test_files' do
      before do
        create_path_table
        subject.send(:delete_test_files)
      end

      after { clear_target_dir }

      describe 'scenario' do
        context 'tracked file' do
          specify { expect(target_dir_files).not_to include('target_file_1') }
          specify { expect(target_dir_files).not_to include('target_file_2') }
        end

        context 'not tracked file' do
          specify { expect(target_dir_files).to include('not_target_file') }
        end
      end
    end

    describe '#restore_tracking_files' do
      before do
        create_path_table
        set_tmp_dir
        subject.send(:move_to_tmp_dir)
        subject.send(:create_nonexistent_dirs)
        subject.send(:restore_tracking_files)
      end

      after { clear_target_dir }

      context 'tmp dir' do
        specify { expect(get_dir_files(tmp_dir)).to be_empty }
      end

      context 'target dir' do
        specify { expect(target_dir_files).not_to be_empty }
        specify { expect(target_dir_files).to include('target_file_1') }
        specify { expect(target_dir_files).to include('target_file_2') }
        specify { expect(target_dir_files).not_to include('target_file_3') }
      end
    end

    describe '#candidate_to_erase' do
      before { create_path_table }
      after { clear_target_dir }

      describe 'scenario' do
        context 'depth level not equal zero' do
          let(:not_zero_level) { subject.path_table['target_file_3'] }
          specify do
            expect(subject.send(:candidate_to_erase, not_zero_level)).to eq("#{target_dir}/virtual_dir_1")
          end
        end

        context 'depth level equal zero' do
          let(:zero_level) { subject.path_table['target_file_1'] }
          specify do
            expect(subject.send(:candidate_to_erase, zero_level)).to eq(target_dir)
          end
        end
      end
    end

    describe '#delete_nonexistent_dirs' do
      before do
        create_path_table
        clear_target_dir
        subject.send(:create_nonexistent_dirs)
        subject.send(:delete_nonexistent_dirs)
      end

      let(:target_dir_dirs) do
        Dir[File.join(File.expand_path(target_dir), '*')].select { |entry| File.directory?(entry) }
      end

      let(:total_nonexistent_dirs) do
        target_dir_dirs.count { |dir| !nonexistent_dir?(dir) }
      end

      specify do
        expect(total_nonexistent_dirs).to be_zero
      end
    end
  end
end
